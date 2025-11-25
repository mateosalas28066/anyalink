# anyalink_bridge_unified.py
# (ES) Bridge unificado: Supabase <-> Kasa (Lampara) + Tapo HS300 (Fuente, Ventilador)
# Mejoras: re-login Tapo, alias normalizados, anti-rebote por alias, refresh children, rediscover por MAC/IP.

import asyncio, time
import datetime as dt
from typing import Optional, Tuple, Dict
import requests
from kasa import SmartBulb, Discover, Credentials, Device

# ---------- DEMO: hardcode (luego pasamos a env) ----------
SUPABASE_URL  = "https://vnalfxtgewdefpoxkuwu.supabase.co".rstrip("/")
SUPABASE_ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZuYWxmeHRnZXdkZWZwb3hrdXd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1NjUwNjQsImV4cCI6MjA3NDE0MTA2NH0.3OVHiVAgI9WUJZ4ar3YVOH49N_IAEEwN2f7TBJhXg9M"

# Bombillo Kasa
KASA_LAMP = {
    "db_alias": "Lampara",              # alias en DB
    "mac": "28:87:ba:4e:77:a1",         # MAC bombillo
    "ip_hint": None                     # p.ej. "192.168.0.14"
}

# Regleta Tapo (HS300)
TAPO_STRIP = {
    "mac": "34:60:f9:cb:3c:92",         # MAC regleta
    "ip_hint": "192.168.0.8",           # última IP conocida (se redescubre si cambia)
     "email": "mateosalas28@hotmail.com", # *** RELLENAR *** (mismo que usaste en Tapo)
    "password": "superyespa123", # <<< RELLENAR
    "children": [
        {"child_alias": "Fuente",     "db_alias": "Fuente"},
        {"child_alias": "Ventilador", "db_alias": "Ventilador"},
    ]
}
# ----------------------------------------------------------

POLL_SECS = 1.2
REDISCOVER_EVERY = 30
WRITE_COOLDOWN   = 1.0      # anti eco DB<->HW (s)
PENDING_WINDOW   = 1.5      # ventana de “comando reciente” (s) por alias

HDRS = {
    "apikey": SUPABASE_ANON,
    "Authorization": f"Bearer {SUPABASE_ANON}",
    "Content-Type": "application/json",
}

_last_write_ts: Dict[str, float]  = {}     # cooldown por alias
_pending_until: Dict[str, float] = {}      # ventana post-comando por alias

# ---------- Utilidades ----------
def _can_write(alias: str) -> bool:
    return (time.time() - _last_write_ts.get(alias, 0.0)) > WRITE_COOLDOWN

def _mark_write(alias: str):
    _last_write_ts[alias] = time.time()

def _set_pending(alias: str):
    _pending_until[alias] = time.time() + PENDING_WINDOW

def _is_pending(alias: str) -> bool:
    return time.time() < _pending_until.get(alias, 0.0)

def _norm_mac(s: str) -> str:
    return "".join(c for c in s.lower() if c in "0123456789abcdef")

def _norm_alias(s: str) -> str:
    # normaliza: lower + trim + colapsa espacios
    return " ".join((s or "").strip().lower().split())

def get_db_row_by_alias(alias: str):
    url = f"{SUPABASE_URL}/rest/v1/devices"
    params = {"alias": f"eq.{alias}", "select": "id,state,updated_at"}
    r = requests.get(url, headers=HDRS, params=params, timeout=10)
    r.raise_for_status()
    data = r.json()
    if not data: return None
    row = data[0]
    return row["id"], bool(row["state"]), row["updated_at"]

def update_db_state_by_id(row_id: str, new_state: bool) -> None:
    url = f"{SUPABASE_URL}/rest/v1/devices"
    params = {"id": f"eq.{row_id}"}
    payload = {"state": new_state, "updated_at": dt.datetime.now(dt.timezone.utc).isoformat()}
    r = requests.patch(url, params=params, json=payload, headers={**HDRS, "Prefer":"return=minimal"}, timeout=10)
    r.raise_for_status()

def parse_ts(ts: str) -> dt.datetime:
    return dt.datetime.fromisoformat(ts.replace("Z","+00:00"))

# ---------- Bombillo Kasa ----------
async def _find_ip_by_mac_kasa(mac_norm: str) -> Optional[str]:
    try:
        found = await Discover.discover()
    except Exception:
        return None
    for ip, dev in found.items():
        try:
            await dev.update()
            mac = getattr(dev,"mac",None) or getattr(dev,"mac_address",None) or ""
            if _norm_mac(mac) == mac_norm:
                return ip
        except Exception:
            continue
    return None

async def _connect_bulb(ip: str) -> SmartBulb:
    b = SmartBulb(ip)
    await b.update()
    return b

async def ensure_kasa_bulb(mac: str, ip_hint: Optional[str]):
    mac_norm = _norm_mac(mac)
    if ip_hint:
        try:
            b = await _connect_bulb(ip_hint); return b, ip_hint
        except Exception: pass
    ip = await _find_ip_by_mac_kasa(mac_norm)
    if not ip: raise RuntimeError("Kasa bulb not found by MAC.")
    b = await _connect_bulb(ip); return b, ip

# ---------- Regleta Tapo (SMART/KLAP) ----------
async def connect_tapo(ip: Optional[str], mac: Optional[str], email: str, password: str):
    creds = Credentials(email, password)
    async def by_ip(ip_addr: str):
        dev = await Discover.discover_single(ip_addr, credentials=creds, discovery_timeout=8)
        if dev is None: raise RuntimeError(f"No Tapo device at {ip_addr}")
        await dev.update()  # session OK
        return dev, ip_addr
    if ip:
        try: return await by_ip(ip)
        except Exception: pass
    if mac:
        mac_norm = _norm_mac(mac)
        try:
            found = await Discover.discover()
            for ip_addr, dev in found.items():
                try:
                    await dev.update(credentials=creds)
                    dmac = getattr(dev,"mac",None) or getattr(dev,"mac_address",None) or ""
                    if _norm_mac(dmac) == mac_norm:
                        return dev, ip_addr
                except Exception:
                    continue
        except Exception:
            pass
    raise RuntimeError("Tapo strip not found (IP/MAC).")

async def get_tapo_children_map(dev) -> Dict[str, object]:
    # refresca info del padre y mapea alias normalizado -> child
    await dev.update()
    out: Dict[str, object] = {}
    for ch in (getattr(dev,"children",None) or []):
        try:
            await ch.update()
        except Exception:
            pass
        out[_norm_alias(getattr(ch,"alias",""))] = ch
    return out

# ---------- Loop ----------
async def main():
    print("[CFG] Bridge unificado iniciado…")
    # Conexión Kasa
    bulb, kasa_ip = await ensure_kasa_bulb(KASA_LAMP["mac"], KASA_LAMP.get("ip_hint"))
    print(f"[KASA] OK @ {kasa_ip}")
    # Conexión Tapo
    tapo_dev, tapo_ip = await connect_tapo(TAPO_STRIP.get("ip_hint"), TAPO_STRIP.get("mac"),
                                           TAPO_STRIP["email"], TAPO_STRIP["password"])
    print(f"[TAPO] OK @ {tapo_ip}")

    prev_db: Dict[str, Optional[bool]] = {"Lampara": None, "Fuente": None, "Ventilador": None}
    prev_hw: Dict[str, Optional[bool]] = {"Lampara": None, "Fuente": None, "Ventilador": None}
    cycles = 0

    while True:
        try:
            # ------- Lampara (Kasa) -------
            row = get_db_row_by_alias(KASA_LAMP["db_alias"])
            if row:
                row_id, db_state, db_ts = row; _ = parse_ts(db_ts)
                try:
                    await bulb.update()
                except Exception:
                    try: bulb = await _connect_bulb(kasa_ip)
                    except Exception:
                        bulb, kasa_ip = await ensure_kasa_bulb(KASA_LAMP["mac"], None)
                    await bulb.update()
                kasa_state = bool(bulb.is_on)

                db_changed = (prev_db["Lampara"] is not None) and (db_state != prev_db["Lampara"])
                hw_changed = (prev_hw["Lampara"] is not None) and (kasa_state != prev_hw["Lampara"])

                if db_changed and _can_write("Lampara"):
                    if db_state and not kasa_state: await bulb.turn_on();  await bulb.update()
                    elif (not db_state) and kasa_state: await bulb.turn_off(); await bulb.update()
                    _mark_write("Lampara"); _set_pending("Lampara")
                    print(f"[KASA] DB->HW: {db_state}")

                elif hw_changed and _can_write("Lampara") and not _is_pending("Lampara"):
                    update_db_state_by_id(row_id, kasa_state)
                    _mark_write("Lampara")
                    print(f"[KASA] HW->DB: {kasa_state}")

                elif kasa_state != db_state and _can_write("Lampara") and not _is_pending("Lampara"):
                    # Fallback: preferimos DB
                    if db_state and not kasa_state: await bulb.turn_on();  await bulb.update()
                    elif (not db_state) and kasa_state: await bulb.turn_off(); await bulb.update()
                    _mark_write("Lampara"); _set_pending("Lampara")
                    print(f"[KASA] Align(DB): {db_state}")

                prev_db["Lampara"] = db_state
                prev_hw["Lampara"] = bool(bulb.is_on)

            # ------- Tapo (children) -------
            try:
                child_map = await get_tapo_children_map(tapo_dev)
            except Exception:
                tapo_dev, tapo_ip = await connect_tapo(TAPO_STRIP.get("ip_hint"), TAPO_STRIP.get("mac"),
                                                       TAPO_STRIP["email"], TAPO_STRIP["password"])
                child_map = await get_tapo_children_map(tapo_dev)

            for child_cfg in TAPO_STRIP["children"]:
                db_alias    = child_cfg["db_alias"]
                child_alias = child_cfg["child_alias"]
                norm_child  = _norm_alias(child_alias)

                row = get_db_row_by_alias(db_alias)
                if not row: continue
                row_id, db_state, db_ts = row; _ = parse_ts(db_ts)

                child = child_map.get(norm_child)
                if child is None:
                    # reintento de refresco puntual
                    child_map = await get_tapo_children_map(tapo_dev)
                    child = child_map.get(norm_child)
                    if child is None:
                        print(f"[TAPO] Child '{child_alias}' no encontrado.")
                        continue

                try:
                    await child.update()
                except Exception:
                    # si falla child.update, reconectar strip completo
                    tapo_dev, tapo_ip = await connect_tapo(TAPO_STRIP.get("ip_hint"), TAPO_STRIP.get("mac"),
                                                           TAPO_STRIP["email"], TAPO_STRIP["password"])
                    child_map = await get_tapo_children_map(tapo_dev)
                    child = child_map.get(norm_child)
                    if child is None: 
                        print(f"[TAPO] Child '{child_alias}' no encontrado tras reconnect.")
                        continue

                hw_state = bool(getattr(child, "is_on", False))
                db_changed = (prev_db.get(db_alias) is not None) and (db_state != prev_db.get(db_alias))
                hw_changed = (prev_hw.get(db_alias) is not None) and (hw_state != prev_hw.get(db_alias))

                if db_changed and _can_write(db_alias):
                    if db_state and not hw_state: await child.turn_on();  await child.update()
                    elif (not db_state) and hw_state: await child.turn_off(); await child.update()
                    _mark_write(db_alias); _set_pending(db_alias)
                    print(f"[TAPO:{child_alias}] DB->HW: {db_state}")

                elif hw_changed and _can_write(db_alias) and not _is_pending(db_alias):
                    update_db_state_by_id(row_id, bool(getattr(child,"is_on",False)))
                    _mark_write(db_alias)
                    print(f"[TAPO:{child_alias}] HW->DB: {bool(getattr(child,'is_on',False))}")

                elif hw_state != db_state and _can_write(db_alias) and not _is_pending(db_alias):
                    if db_state and not hw_state: await child.turn_on();  await child.update()
                    elif (not db_state) and hw_state: await child.turn_off(); await child.update()
                    _mark_write(db_alias); _set_pending(db_alias)
                    print(f"[TAPO:{child_alias}] Align(DB): {db_state}")

                prev_db[db_alias] = db_state
                prev_hw[db_alias] = bool(getattr(child,"is_on",False))

            # -------- Rediscovery periódico --------
            cycles += 1
            if cycles >= REDISCOVER_EVERY:
                # Kasa: IP por MAC
                try:
                    ip2 = await _find_ip_by_mac_kasa(_norm_mac(KASA_LAMP["mac"]))
                    if ip2 and ip2 != kasa_ip:
                        bulb = await _connect_bulb(ip2); kasa_ip = ip2
                        print("[KASA] IP changed ->", kasa_ip)
                except Exception: pass
                # Tapo: re-login
                try:
                    tapo_dev, ip2 = await connect_tapo(TAPO_STRIP.get("ip_hint"), TAPO_STRIP.get("mac"),
                                                       TAPO_STRIP["email"], TAPO_STRIP["password"])
                    if ip2 != tapo_ip:
                        tapo_ip = ip2; print("[TAPO] IP changed ->", tapo_ip)
                except Exception: pass
                cycles = 0

        except Exception as e:
            print("Bridge loop error:", e)

        await asyncio.sleep(POLL_SECS)

if __name__ == "__main__":
    asyncio.run(main())
