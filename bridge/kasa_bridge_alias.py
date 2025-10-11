# kasa_bridge_alias.py
# Comentario (ES): Bridge Kasa <-> Supabase por ALIAS (sin .bat, credenciales en código).
# - SmartBulb (estable), discover por MAC para refrescar IP.
# - Cooldown para evitar rebotes DB<->Kasa.

import time
import asyncio
import datetime as dt
from typing import Optional, Tuple

import requests
from kasa import SmartBulb, Discover

# ---------- TUS DATOS (hardcode) ----------
SUPABASE_URL = "https://vnalfxtgewdefpoxkuwu.supabase.co".rstrip("/")
SUPABASE_ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZuYWxmeHRnZXdkZWZwb3hrdXd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1NjUwNjQsImV4cCI6MjA3NDE0MTA2NH0.3OVHiVAgI9WUJZ4ar3YVOH49N_IAEEwN2f7TBJhXg9M"
DEVICE_ALIAS = "Lampara"
KASA_MAC = "28:87:ba:4e:77:a1"  # para revalidar IP si cambia
KASA_IP_HINT = "192.168.0.2"  # IP actual conocida
# -----------------------------------------

POLL_SECS = 1
REDISCOVER_EVERY = 30
WRITE_COOLDOWN = 0.8  # seg: evita eco DB<->Kasa

HDRS = {
    "apikey": SUPABASE_ANON,
    "Authorization": f"Bearer {SUPABASE_ANON}",
    "Content-Type": "application/json",
}

_LAST_WRITE_TS = 0.0


def _can_write() -> bool:
    return (time.time() - _LAST_WRITE_TS) > WRITE_COOLDOWN


def _mark_write():
    global _LAST_WRITE_TS
    _LAST_WRITE_TS = time.time()


def _norm_mac(s: str) -> str:
    return "".join(c for c in s.lower() if c in "0123456789abcdef")


def get_db_row_by_alias(alias: str) -> Optional[Tuple[str, bool, str]]:
    url = f"{SUPABASE_URL}/rest/v1/devices"
    params = {"alias": f"eq.{alias}", "select": "id,state,updated_at"}
    resp = requests.get(url, headers=HDRS, params=params, timeout=10)
    resp.raise_for_status()
    data = resp.json()
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
    resp = requests.patch(
        url,
        params=params,
        json=payload,
        headers={**HDRS, "Prefer": "return=minimal"},
        timeout=10,
    )
    resp.raise_for_status()


def parse_ts(ts: str) -> dt.datetime:
    return dt.datetime.fromisoformat(ts.replace("Z", "+00:00"))


async def find_ip_by_mac(mac_norm: str) -> Optional[str]:
    try:
        found = await Discover.discover()
    except Exception as e:
        print("Discover failed:", e)
        return None
    for ip, dev in found.items():
        try:
            await dev.update()
            mac = getattr(dev, "mac", None) or getattr(dev, "mac_address", None) or ""
            if _norm_mac(mac) == mac_norm:
                return ip
        except Exception:
            continue
    return None


async def connect_bulb(ip: str) -> SmartBulb:
    bulb = SmartBulb(ip)
    await bulb.update()
    return bulb


async def ensure_bulb(mac_norm: Optional[str], ip_hint: Optional[str]) -> Tuple[SmartBulb, str]:
    if ip_hint:
        try:
            b = await connect_bulb(ip_hint)
            return b, ip_hint
        except Exception as e:
            print(f"Direct IP connect failed for {ip_hint}:", e)
    if mac_norm:
        ip = await find_ip_by_mac(mac_norm)
        if ip:
            b = await connect_bulb(ip)
            return b, ip
        print("MAC discovery failed; check device is on and same LAN.")
    raise RuntimeError("Could not connect to Kasa device (IP/MAC).")


async def main():
    print(f"[CFG] alias={DEVICE_ALIAS} mac={KASA_MAC} ip_hint={KASA_IP_HINT}")
    mac_norm = _norm_mac(KASA_MAC) if KASA_MAC else None
    ip_hint = KASA_IP_HINT or None

    bulb, current_ip = await ensure_bulb(mac_norm, ip_hint)
    print("Bridge running. Initial IP:", current_ip)

    prev_db_state: Optional[bool] = None
    prev_kasa_state: Optional[bool] = None
    cycles = 0

    while True:
        try:
            row = get_db_row_by_alias(DEVICE_ALIAS)
            if row is None:
                print(f"DB row not found for alias '{DEVICE_ALIAS}'.")
                await asyncio.sleep(POLL_SECS)
                continue
            row_id, db_state, db_ts = row
            _ = parse_ts(db_ts)

            # Refrescar bombilla
            try:
                await bulb.update()
            except Exception as e:
                print("Bulb update failed; reconnecting...", e)
                try:
                    bulb = await connect_bulb(current_ip)
                except Exception:
                    bulb, current_ip = await ensure_bulb(mac_norm, None)
                print("Reconnected to IP:", current_ip)
                await bulb.update()

            kasa_state = bool(bulb.is_on)

            db_changed = (prev_db_state is not None) and (db_state != prev_db_state)
            kasa_changed = (prev_kasa_state is not None) and (kasa_state != prev_kasa_state)

            if db_changed and _can_write():
                # DB -> Kasa
                if db_state and not kasa_state:
                    await bulb.turn_on()
                    await bulb.update()
                elif (not db_state) and kasa_state:
                    await bulb.turn_off()
                    await bulb.update()
                _mark_write()
                print(f"Applied DB->Kasa: {db_state}")

            elif kasa_changed and _can_write():
                # Kasa -> DB
                update_db_state_by_id(row_id, kasa_state)
                _mark_write()
                print(f"Applied Kasa->DB: {kasa_state}")

            else:
                if kasa_state != db_state and _can_write():
                    if db_state and not kasa_state:
                        await bulb.turn_on()
                        await bulb.update()
                    elif (not db_state) and kasa_state:
                        await bulb.turn_off()
                        await bulb.update()
                    _mark_write()
                    print(f"Aligned to DB (fallback): {db_state}")

            prev_db_state = db_state
            prev_kasa_state = bool(bulb.is_on)

            # Revalidar IP periódicamente (cambio por DHCP)
            cycles += 1
            if mac_norm and cycles >= REDISCOVER_EVERY:
                ip2 = await find_ip_by_mac(mac_norm)
                if ip2 and ip2 != current_ip:
                    print("IP changed by DHCP; switching to", ip2)
                    bulb = await connect_bulb(ip2)
                    current_ip = ip2
                cycles = 0

        except Exception as loop_err:
            print("Bridge loop error:", loop_err)

        await asyncio.sleep(POLL_SECS)


if __name__ == "__main__":
    asyncio.run(main())
