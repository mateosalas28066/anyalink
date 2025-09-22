# bridge/kasa_bridge_mac.py
# Comentario (ES): Bridge Kasa <-> Supabase con detección de cambios por valor (DB y Kasa),
# redescubre IP por MAC y evita "rebotes" cuando editas manualmente en Table Editor.
import os
import time
import asyncio
import datetime as dt
import requests
from kasa import SmartBulb, Discover

SUPABASE_URL   = os.environ["SUPABASE_URL"].rstrip("/")
SUPABASE_ANON  = os.environ["SUPABASE_ANON"]
DEVICE_ROW_ID  = os.environ["DEVICE_ROW_ID"]
KASA_MAC_ENV   = os.environ.get("KASA_MAC", "")
KASA_IP_ENV    = os.environ.get("KASA_IP", "")

POLL_SECS        = 2
REDISCOVER_EVERY = 30

HDRS = {
    "apikey": SUPABASE_ANON,
    "Authorization": f"Bearer {SUPABASE_ANON}",
    "Content-Type": "application/json",
}

def _norm_mac(s: str) -> str:
    return "".join(c for c in s.lower() if c in "0123456789abcdef")

def get_db_row():
    url = f"{SUPABASE_URL}/rest/v1/devices?id=eq.{DEVICE_ROW_ID}&select=state,updated_at"
    r = requests.get(url, headers=HDRS, timeout=10); r.raise_for_status()
    data = r.json()
    if not data: return None
    row = data[0]
    return bool(row["state"]), row["updated_at"]

def update_db_state(new_state: bool):
    url = f"{SUPABASE_URL}/rest/v1/devices?id=eq.{DEVICE_ROW_ID}"
    payload = {"state": new_state, "updated_at": dt.datetime.now(dt.timezone.utc).isoformat()}
    r = requests.patch(url, json=payload, headers={**HDRS, "Prefer": "return=minimal"}, timeout=10)
    r.raise_for_status()

def parse_ts(ts: str) -> dt.datetime:
    return dt.datetime.fromisoformat(ts.replace("Z", "+00:00"))

async def discover_ip_by_mac(target_mac_norm: str) -> str | None:
    try:
        found = await Discover.discover()
        for ip, dev in found.items():
            mac = getattr(dev, "mac", None) or getattr(dev, "mac_address", None) or ""
            if _norm_mac(mac) == target_mac_norm:
                return ip
    except Exception:
        return None
    return None

async def ensure_bulb(mac_norm: str, cached_ip: str | None) -> tuple[SmartBulb, str]:
    if cached_ip:
        b = SmartBulb(cached_ip)
        try:
            await b.update()
            return b, cached_ip
        except Exception:
            pass
    ip = await discover_ip_by_mac(mac_norm)
    if not ip:
        raise RuntimeError("Could not discover Kasa device by MAC on LAN.")
    b = SmartBulb(ip)
    await b.update()
    return b, ip

async def main():
    mac_norm = _norm_mac(KASA_MAC_ENV)
    if not mac_norm:
        raise RuntimeError("KASA_MAC env var is required (device MAC).")

    cached_ip = KASA_IP_ENV or None
    cycles_since_discover = 0

    bulb, cached_ip = await ensure_bulb(mac_norm, cached_ip)
    print("Bridge running. Initial IP:", cached_ip)

    # Comentario (ES): Estados previos para detectar cambios reales
    prev_db_state: bool | None = None
    prev_kasa_state: bool | None = None
    prev_db_ts: dt.datetime | None = None

    while True:
        try:
            # 1) Leer DB
            row = get_db_row()
            if row is None:
                print("DB row not found. Check DEVICE_ROW_ID.")
                time.sleep(POLL_SECS); continue
            db_state, db_ts_str = row
            db_ts = parse_ts(db_ts_str) if isinstance(db_ts_str, str) else dt.datetime.now(dt.timezone.utc)

            # 2) Leer Kasa
            try:
                await bulb.update()
            except Exception as e:
                print("Bulb update failed, rediscovering by MAC...", e)
                bulb, cached_ip = await ensure_bulb(mac_norm, None)
                print("Reconnected to IP:", cached_ip)
                await bulb.update()

            kasa_state = bool(bulb.is_on)

            # 3) Reglas de conciliación
            # Regla A: si DB cambió de valor respecto al último ciclo -> DB manda.
            db_changed = (prev_db_state is not None) and (db_state != prev_db_state)

            # Regla B: si Kasa cambió y DB NO cambió -> Kasa manda.
            kasa_changed = (prev_kasa_state is not None) and (kasa_state != prev_kasa_state)

            if db_changed:
                # DB -> Kasa
                if db_state and not kasa_state:
                    await bulb.turn_on(); await bulb.update()
                elif (not db_state) and kasa_state:
                    await bulb.turn_off(); await bulb.update()
                print(f"Applied DB->Kasa: {db_state}")

            elif kasa_changed:
                # Kasa -> DB
                update_db_state(kasa_state)
                print(f"Applied Kasa->DB: {kasa_state}")

            else:
                # Sin cambios declarados, pero si hay desalineación, preferimos DB (o usa ventana de tiempo)
                if kasa_state != db_state:
                    # Fallback: DB manda para evitar rebotes
                    if db_state and not kasa_state:
                        await bulb.turn_on(); await bulb.update()
                    elif (not db_state) and kasa_state:
                        await bulb.turn_off(); await bulb.update()
                    print(f"Aligned to DB (fallback): {db_state}")

            # 4) Guardar estados previos
            prev_db_state = db_state
            prev_kasa_state = kasa_state
            prev_db_ts = db_ts

            # 5) Re-descubrir periódicamente por cambios de IP (DHCP)
            cycles_since_discover += 1
            if cycles_since_discover >= REDISCOVER_EVERY:
                ip2 = await discover_ip_by_mac(mac_norm)
                if ip2 and ip2 != cached_ip:
                    print("IP changed by DHCP; switching from", cached_ip, "to", ip2)
                    bulb = SmartBulb(ip2); await bulb.update()
                    cached_ip = ip2
                cycles_since_discover = 0

        except Exception as e:
            print("Bridge loop error:", e)

        time.sleep(POLL_SECS)

if __name__ == "__main__":
    asyncio.run(main())
