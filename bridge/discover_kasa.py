# discover_kasa.py
# Comentario (ES): Descubre dispositivos Kasa en tu LAN e imprime IP, modelo, MAC y alias.
import asyncio
from kasa import Discover

async def main():
    found = await Discover.discover()  # broadcast en la LAN
    if not found:
        print("No Kasa devices found. Ensure same LAN (no 'guest' Wi-Fi) and allow Python in firewall.")
    for ip, dev in found.items():
        await dev.update()
        print(f"{ip} | model={dev.model} | mac={dev.mac} | alias={dev.alias}")

asyncio.run(main())
