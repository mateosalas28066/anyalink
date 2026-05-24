# anyalink_bridge_unified.example.py
# Example bridge: Supabase <-> Kasa bulb + Tapo/HS300 child plugs.
#
# Copy this file to anyalink_bridge_unified.py and configure the environment
# variables below. Do not commit local files with real credentials.

import asyncio
import datetime as dt
import os
import time
from typing import Dict, Optional

import requests
from kasa import Credentials, Discover, SmartBulb


def _env_required(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def _env_optional(name: str) -> Optional[str]:
    value = os.environ.get(name)
    return value or None


# Supabase REST credentials. Use an anon key only if RLS allows this bridge.
# For privileged keys, keep this script on a trusted local machine only.
SUPABASE_URL = _env_required("ANYALINK_SUPABASE_URL").rstrip("/")
SUPABASE_KEY = _env_required("ANYALINK_SUPABASE_KEY")

# Kasa bulb configuration.
KASA_LAMP = {
    "db_alias": os.environ.get("ANYALINK_KASA_DB_ALIAS", "Lampara"),
    "mac": _env_required("ANYALINK_KASA_MAC"),
    "ip_hint": _env_optional("ANYALINK_KASA_IP"),
}

# Tapo/HS300 strip configuration.
TAPO_STRIP = {
    "mac": _env_required("ANYALINK_TAPO_MAC"),
    "ip_hint": _env_optional("ANYALINK_TAPO_IP"),
    "email": _env_required("ANYALINK_TAPO_EMAIL"),
    "password": _env_required("ANYALINK_TAPO_PASSWORD"),
    "children": [
        {
            "child_alias": os.environ.get("ANYALINK_TAPO_CHILD_1_ALIAS", "Fuente"),
            "db_alias": os.environ.get("ANYALINK_TAPO_CHILD_1_DB_ALIAS", "Fuente"),
        },
        {
            "child_alias": os.environ.get("ANYALINK_TAPO_CHILD_2_ALIAS", "Ventilador"),
            "db_alias": os.environ.get("ANYALINK_TAPO_CHILD_2_DB_ALIAS", "Ventilador"),
        },
    ],
}

POLL_SECS = float(os.environ.get("ANYALINK_POLL_SECS", "0.2"))
REDISCOVER_EVERY = int(os.environ.get("ANYALINK_REDISCOVER_EVERY", "30"))
WRITE_COOLDOWN = float(os.environ.get("ANYALINK_WRITE_COOLDOWN", "0.2"))
PENDING_WINDOW = float(os.environ.get("ANYALINK_PENDING_WINDOW", "0.4"))

HDRS = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
}

_last_write_ts: Dict[str, float] = {}
_pending_until: Dict[str, float] = {}


def _can_write(alias: str) -> bool:
    return (time.time() - _last_write_ts.get(alias, 0.0)) > WRITE_COOLDOWN


def _mark_write(alias: str) -> None:
    _last_write_ts[alias] = time.time()


def _set_pending(alias: str) -> None:
    _pending_until[alias] = time.time() + PENDING_WINDOW


def _is_pending(alias: str) -> bool:
    return time.time() < _pending_until.get(alias, 0.0)


def _norm_mac(value: str) -> str:
    return "".join(c for c in value.lower() if c in "0123456789abcdef")


def _norm_alias(value: str) -> str:
    return " ".join((value or "").strip().lower().split())


def get_db_row_by_alias(alias: str):
    url = f"{SUPABASE_URL}/rest/v1/devices"
    params = {"alias": f"eq.{alias}", "select": "id,state,updated_at"}
    response = requests.get(url, headers=HDRS, params=params, timeout=10)
    response.raise_for_status()
    data = response.json()
    if not data:
        return None
    row = data[0]
    return row["id"], bool(row["state"]), row["updated_at"]


def update_db_state_by_id(row_id: str, new_state: bool) -> None:
    url = f"{SUPABASE_URL}/rest/v1/devices"
    params = {"id": f"eq.{row_id}"}
    payload = {
        "state": new_state,
        "updated_at": dt.datetime.now(dt.timezone.utc).isoformat(),
    }
    response = requests.patch(
        url,
        params=params,
        json=payload,
        headers={**HDRS, "Prefer": "return=minimal"},
        timeout=10,
    )
    response.raise_for_status()


def parse_ts(value: str) -> dt.datetime:
    return dt.datetime.fromisoformat(value.replace("Z", "+00:00"))


async def _find_ip_by_mac_kasa(mac_norm: str) -> Optional[str]:
    try:
        found = await Discover.discover()
    except Exception:
        return None

    for ip_addr, dev in found.items():
        try:
            await dev.update()
            mac = getattr(dev, "mac", None) or getattr(dev, "mac_address", None) or ""
            if _norm_mac(mac) == mac_norm:
                return ip_addr
        except Exception:
            continue
    return None


async def _connect_bulb(ip_addr: str) -> SmartBulb:
    bulb = SmartBulb(ip_addr)
    await bulb.update()
    return bulb


async def ensure_kasa_bulb(mac: str, ip_hint: Optional[str]):
    mac_norm = _norm_mac(mac)
    if ip_hint:
        try:
            bulb = await _connect_bulb(ip_hint)
            return bulb, ip_hint
        except Exception:
            pass

    ip_addr = await _find_ip_by_mac_kasa(mac_norm)
    if not ip_addr:
        raise RuntimeError("Kasa bulb not found by MAC.")
    bulb = await _connect_bulb(ip_addr)
    return bulb, ip_addr


async def connect_tapo(ip: Optional[str], mac: Optional[str], email: str, password: str):
    creds = Credentials(email, password)

    async def by_ip(ip_addr: str):
        dev = await Discover.discover_single(
            ip_addr,
            credentials=creds,
            discovery_timeout=8,
        )
        if dev is None:
            raise RuntimeError(f"No Tapo device at {ip_addr}")
        await dev.update()
        return dev, ip_addr

    if ip:
        try:
            return await by_ip(ip)
        except Exception:
            pass

    if mac:
        mac_norm = _norm_mac(mac)
        try:
            found = await Discover.discover()
            for ip_addr, dev in found.items():
                try:
                    await dev.update(credentials=creds)
                    dev_mac = (
                        getattr(dev, "mac", None)
                        or getattr(dev, "mac_address", None)
                        or ""
                    )
                    if _norm_mac(dev_mac) == mac_norm:
                        return dev, ip_addr
                except Exception:
                    continue
        except Exception:
            pass

    raise RuntimeError("Tapo strip not found by IP/MAC.")


async def get_tapo_children_map(dev) -> Dict[str, object]:
    await dev.update()
    out: Dict[str, object] = {}
    for child in getattr(dev, "children", None) or []:
        try:
            await child.update()
        except Exception:
            pass
        out[_norm_alias(getattr(child, "alias", ""))] = child
    return out


async def _sync_kasa_lamp(bulb, kasa_ip, prev_db, prev_hw):
    db_alias = KASA_LAMP["db_alias"]
    row = get_db_row_by_alias(db_alias)
    if not row:
        return bulb, kasa_ip

    row_id, db_state, db_ts = row
    _ = parse_ts(db_ts)

    try:
        await bulb.update()
    except Exception:
        try:
            bulb = await _connect_bulb(kasa_ip)
        except Exception:
            bulb, kasa_ip = await ensure_kasa_bulb(KASA_LAMP["mac"], None)
        await bulb.update()

    hw_state = bool(bulb.is_on)
    db_changed = prev_db.get(db_alias) is not None and db_state != prev_db.get(db_alias)
    hw_changed = prev_hw.get(db_alias) is not None and hw_state != prev_hw.get(db_alias)

    if db_changed and _can_write(db_alias):
        if db_state and not hw_state:
            await bulb.turn_on()
            await bulb.update()
        elif not db_state and hw_state:
            await bulb.turn_off()
            await bulb.update()
        _mark_write(db_alias)
        _set_pending(db_alias)
        print(f"[KASA] DB->HW: {db_state}")

    elif hw_changed and _can_write(db_alias) and not _is_pending(db_alias):
        update_db_state_by_id(row_id, hw_state)
        _mark_write(db_alias)
        print(f"[KASA] HW->DB: {hw_state}")

    elif hw_state != db_state and _can_write(db_alias) and not _is_pending(db_alias):
        if db_state and not hw_state:
            await bulb.turn_on()
            await bulb.update()
        elif not db_state and hw_state:
            await bulb.turn_off()
            await bulb.update()
        _mark_write(db_alias)
        _set_pending(db_alias)
        print(f"[KASA] Align DB: {db_state}")

    prev_db[db_alias] = db_state
    prev_hw[db_alias] = bool(bulb.is_on)
    return bulb, kasa_ip


async def _sync_tapo_children(tapo_dev, tapo_ip, prev_db, prev_hw):
    try:
        child_map = await get_tapo_children_map(tapo_dev)
    except Exception:
        tapo_dev, tapo_ip = await connect_tapo(
            TAPO_STRIP.get("ip_hint"),
            TAPO_STRIP.get("mac"),
            TAPO_STRIP["email"],
            TAPO_STRIP["password"],
        )
        child_map = await get_tapo_children_map(tapo_dev)

    for child_cfg in TAPO_STRIP["children"]:
        db_alias = child_cfg["db_alias"]
        child_alias = child_cfg["child_alias"]
        row = get_db_row_by_alias(db_alias)
        if not row:
            continue

        row_id, db_state, db_ts = row
        _ = parse_ts(db_ts)

        child = child_map.get(_norm_alias(child_alias))
        if child is None:
            child_map = await get_tapo_children_map(tapo_dev)
            child = child_map.get(_norm_alias(child_alias))
            if child is None:
                print(f"[TAPO] Child not found: {child_alias}")
                continue

        try:
            await child.update()
        except Exception:
            tapo_dev, tapo_ip = await connect_tapo(
                TAPO_STRIP.get("ip_hint"),
                TAPO_STRIP.get("mac"),
                TAPO_STRIP["email"],
                TAPO_STRIP["password"],
            )
            child_map = await get_tapo_children_map(tapo_dev)
            child = child_map.get(_norm_alias(child_alias))
            if child is None:
                print(f"[TAPO] Child not found after reconnect: {child_alias}")
                continue

        hw_state = bool(getattr(child, "is_on", False))
        db_changed = prev_db.get(db_alias) is not None and db_state != prev_db.get(db_alias)
        hw_changed = prev_hw.get(db_alias) is not None and hw_state != prev_hw.get(db_alias)

        if db_changed and _can_write(db_alias):
            if db_state and not hw_state:
                await child.turn_on()
                await child.update()
            elif not db_state and hw_state:
                await child.turn_off()
                await child.update()
            _mark_write(db_alias)
            _set_pending(db_alias)
            print(f"[TAPO:{child_alias}] DB->HW: {db_state}")

        elif hw_changed and _can_write(db_alias) and not _is_pending(db_alias):
            update_db_state_by_id(row_id, bool(getattr(child, "is_on", False)))
            _mark_write(db_alias)
            print(f"[TAPO:{child_alias}] HW->DB: {bool(getattr(child, 'is_on', False))}")

        elif hw_state != db_state and _can_write(db_alias) and not _is_pending(db_alias):
            if db_state and not hw_state:
                await child.turn_on()
                await child.update()
            elif not db_state and hw_state:
                await child.turn_off()
                await child.update()
            _mark_write(db_alias)
            _set_pending(db_alias)
            print(f"[TAPO:{child_alias}] Align DB: {db_state}")

        prev_db[db_alias] = db_state
        prev_hw[db_alias] = bool(getattr(child, "is_on", False))

    return tapo_dev, tapo_ip


async def main():
    print("[CFG] Unified bridge started")

    bulb, kasa_ip = await ensure_kasa_bulb(
        KASA_LAMP["mac"],
        KASA_LAMP.get("ip_hint"),
    )
    print(f"[KASA] OK @ {kasa_ip}")

    tapo_dev, tapo_ip = await connect_tapo(
        TAPO_STRIP.get("ip_hint"),
        TAPO_STRIP.get("mac"),
        TAPO_STRIP["email"],
        TAPO_STRIP["password"],
    )
    print(f"[TAPO] OK @ {tapo_ip}")

    aliases = [KASA_LAMP["db_alias"]] + [child["db_alias"] for child in TAPO_STRIP["children"]]
    prev_db: Dict[str, Optional[bool]] = {alias: None for alias in aliases}
    prev_hw: Dict[str, Optional[bool]] = {alias: None for alias in aliases}
    cycles = 0

    while True:
        try:
            bulb, kasa_ip = await _sync_kasa_lamp(bulb, kasa_ip, prev_db, prev_hw)
            tapo_dev, tapo_ip = await _sync_tapo_children(tapo_dev, tapo_ip, prev_db, prev_hw)

            cycles += 1
            if cycles >= REDISCOVER_EVERY:
                try:
                    ip2 = await _find_ip_by_mac_kasa(_norm_mac(KASA_LAMP["mac"]))
                    if ip2 and ip2 != kasa_ip:
                        bulb = await _connect_bulb(ip2)
                        kasa_ip = ip2
                        print(f"[KASA] IP changed -> {kasa_ip}")
                except Exception:
                    pass

                try:
                    tapo_dev, ip2 = await connect_tapo(
                        TAPO_STRIP.get("ip_hint"),
                        TAPO_STRIP.get("mac"),
                        TAPO_STRIP["email"],
                        TAPO_STRIP["password"],
                    )
                    if ip2 != tapo_ip:
                        tapo_ip = ip2
                        print(f"[TAPO] IP changed -> {tapo_ip}")
                except Exception:
                    pass

                cycles = 0

        except Exception as exc:
            print("Bridge loop error:", exc)

        await asyncio.sleep(POLL_SECS)


if __name__ == "__main__":
    asyncio.run(main())
