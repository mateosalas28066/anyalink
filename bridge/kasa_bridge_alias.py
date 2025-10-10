# bridge/kasa_bridge_alias.py
# Comentario (ES): Bridge Kasa <-> Supabase usando alias, configurable por variables de entorno o archivo JSON externo.
# - Prefiere variables de entorno (no guarda credenciales en el repositorio).
# - Opcional: --config path/to/config.json como fallback para dispositivos específicos.

import argparse
import asyncio
import datetime as dt
import json
import os
from pathlib import Path
from typing import Optional, Tuple

import requests
from kasa import Discover

REQUIRED_KEYS = [
    "SUPABASE_URL",
    "SUPABASE_ANON",
    "DEVICE_ALIAS",
    "KASA_IP",
    "KASA_MAC",
]
OPTIONAL_KEYS = {
    "POLL_SECS": 2,
    "REDISCOVER_EVERY": 30,
}


def load_settings(config_path: Optional[Path]):
    env_values = {key: os.environ.get(key) for key in REQUIRED_KEYS}
    if all(env_values.values()):
        poll_secs = int(os.environ.get("POLL_SECS", OPTIONAL_KEYS["POLL_SECS"]))
        rediscover_every = int(os.environ.get("REDISCOVER_EVERY", OPTIONAL_KEYS["REDISCOVER_EVERY"]))
        return {
            "supabase_url": env_values["SUPABASE_URL"].rstrip("/"),
            "supabase_anon": env_values["SUPABASE_ANON"],
            "device_alias": env_values["DEVICE_ALIAS"],
            "kasa_ip": env_values["KASA_IP"],
            "kasa_mac": env_values["KASA_MAC"],
            "poll_secs": poll_secs,
            "rediscover_every": rediscover_every,
        }

    candidate_paths = []
    if config_path is not None:
        candidate_paths.append(config_path)
    else:
        config_dir = Path(__file__).parent
        candidate_paths.extend([
            config_dir / 'config.local.json',
            config_dir / 'config.json',
        ])

    for cfg in candidate_paths:
        if cfg.exists():
            data = json.loads(cfg.read_text(encoding='utf-8-sig'))
            missing = [
                key for key in [
                    'supabase_url',
                    'supabase_anon_key',
                    'device_alias',
                    'kasa_ip',
                    'kasa_mac',
                ]
                if not data.get(key)
            ]
            if missing:
                raise ValueError(f"Config file '{cfg}' is missing keys: {', '.join(missing)}")
            return {
                'supabase_url': str(data['supabase_url']).rstrip('/'),
                'supabase_anon': str(data['supabase_anon_key']),
                'device_alias': str(data['device_alias']),
                'kasa_ip': str(data['kasa_ip']),
                'kasa_mac': str(data['kasa_mac']),
                'poll_secs': int(data.get('poll_secs', OPTIONAL_KEYS['POLL_SECS'])),
                'rediscover_every': int(data.get('rediscover_every', OPTIONAL_KEYS['REDISCOVER_EVERY'])),
            }

    raise RuntimeError(
        "Missing required settings. Set environment variables "
        "(SUPABASE_URL, SUPABASE_ANON, DEVICE_ALIAS, KASA_IP, KASA_MAC) "
        "or provide a config file via --config."
    )


def _norm_mac(value: str) -> str:
    return "".join(ch for ch in value.lower() if ch in "0123456789abcdef")


async def connect_device_by_ip(ip: str):
    device = await Discover.discover_single(ip)
    if device is None:
        raise RuntimeError(f"No Kasa device discovered at {ip}")
    if hasattr(device, "update"):
        await device.update()
    return device


async def discover_device_by_mac(mac_norm: str):
    try:
        found = await Discover.discover()
    except Exception as err:
        print("Discover failed:", err)
        return None, None

    for ip, device in found.items():
        try:
            if hasattr(device, "update"):
                await device.update()
            mac = getattr(device, "mac", None) or getattr(device, "mac_address", None) or ""
            if _norm_mac(mac) == mac_norm:
                return device, ip
        except Exception as inner_err:
            print("MAC discovery attempt failed:", inner_err)
            continue
    return None, None


def get_db_row_by_alias(settings, alias: str) -> Optional[Tuple[str, bool, str]]:
    url = f"{settings['supabase_url']}/rest/v1/devices"
    params = {"alias": f"eq.{alias}", "select": "id,state,updated_at"}
    resp = requests.get(url, headers=settings['hdrs'], params=params, timeout=10)
    resp.raise_for_status()
    data = resp.json()
    if not data:
        return None
    row = data[0]
    return row["id"], bool(row["state"]), row["updated_at"]


def update_db_state_by_id(settings, row_id: str, new_state: bool) -> None:
    url = f"{settings['supabase_url']}/rest/v1/devices"
    params = {"id": f"eq.{row_id}"}
    payload = {
        "state": new_state,
        "updated_at": dt.datetime.now(dt.timezone.utc).isoformat(),
    }
    resp = requests.patch(
        url,
        params=params,
        json=payload,
        headers=settings['hdrs_with_prefer'],
        timeout=10,
    )
    resp.raise_for_status()


def parse_ts(ts: str) -> dt.datetime:
    return dt.datetime.fromisoformat(ts.replace("Z", "+00:00"))


async def ensure_device(mac_norm: str, cached_ip: Optional[str]):
    if cached_ip:
        try:
            device = await connect_device_by_ip(cached_ip)
            return device, cached_ip
        except Exception as err:
            print(f"Connection via cached IP {cached_ip} failed:", err)

    if mac_norm:
        device, ip = await discover_device_by_mac(mac_norm)
        if device is not None and ip:
            return device, ip
        print("Discovery by MAC failed; ensure MAC is correct and device reachable.")

    raise RuntimeError("Could not connect to Kasa device (IP/MAC).")


async def run_bridge(settings) -> None:
    alias = settings['device_alias']
    mac_norm = _norm_mac(settings['kasa_mac'])
    cached_ip = settings['kasa_ip'] or None

    device, cached_ip = await ensure_device(mac_norm, cached_ip)
    print("Bridge (alias) running. Initial IP:", cached_ip or "(discover)")

    prev_db_state: Optional[bool] = None
    prev_kasa_state: Optional[bool] = None
    cycles = 0

    while True:
        try:
            row = get_db_row_by_alias(settings, alias)
            if row is None:
                print(f"DB row not found for alias '{alias}'.")
                await asyncio.sleep(settings['poll_secs'])
                continue

            row_id, db_state, db_ts_str = row
            _ = parse_ts(db_ts_str)

            try:
                if hasattr(device, "update"):
                    await device.update()
            except Exception as err:
                print("Device update failed; reconnecting...", err)
                device, cached_ip = await ensure_device(mac_norm, None)
                print("Reconnected to IP:", cached_ip or "(discover)")
                if hasattr(device, "update"):
                    await device.update()

            kasa_state = bool(getattr(device, "is_on"))

            db_changed = prev_db_state is not None and db_state != prev_db_state
            kasa_changed = prev_kasa_state is not None and kasa_state != prev_kasa_state

            if db_changed:
                if db_state and not kasa_state and hasattr(device, "turn_on"):
                    await device.turn_on()
                    if hasattr(device, "update"):
                        await device.update()
                elif (not db_state) and kasa_state and hasattr(device, "turn_off"):
                    await device.turn_off()
                    if hasattr(device, "update"):
                        await device.update()
                print(f"Applied DB->Kasa: {db_state}")

            elif kasa_changed:
                update_db_state_by_id(settings, row_id, kasa_state)
                print(f"Applied Kasa->DB: {kasa_state}")

            else:
                if kasa_state != db_state:
                    if db_state and not kasa_state and hasattr(device, "turn_on"):
                        await device.turn_on()
                        if hasattr(device, "update"):
                            await device.update()
                    elif (not db_state) and kasa_state and hasattr(device, "turn_off"):
                        await device.turn_off()
                        if hasattr(device, "update"):
                            await device.update()
                    print(f"Aligned to DB (fallback): {db_state}")

            prev_db_state = db_state
            prev_kasa_state = kasa_state

            cycles += 1
            if mac_norm and cycles >= settings['rediscover_every']:
                device2, ip2 = await discover_device_by_mac(mac_norm)
                if device2 is not None and ip2 and ip2 != (cached_ip or ""):
                    print("IP changed by DHCP; switching to", ip2)
                    device = device2
                    cached_ip = ip2
                cycles = 0

        except Exception as loop_err:
            print("Bridge loop error:", loop_err)

        await asyncio.sleep(settings['poll_secs'])


def main():
    parser = argparse.ArgumentParser(description="Supabase <-> Kasa bridge by alias")
    parser.add_argument(
        "--config",
        type=Path,
        help="Ruta opcional a archivo JSON con credenciales y ajustes (solo si no usas variables de entorno)",
    )
    args = parser.parse_args()

    settings = load_settings(args.config)
    settings['hdrs'] = {
        "apikey": settings['supabase_anon'],
        "Authorization": f"Bearer {settings['supabase_anon']}",
        "Content-Type": "application/json",
    }
    settings['hdrs_with_prefer'] = {
        **settings['hdrs'],
        "Prefer": "return=minimal",
    }

    asyncio.run(run_bridge(settings))


if __name__ == "__main__":
    main()
