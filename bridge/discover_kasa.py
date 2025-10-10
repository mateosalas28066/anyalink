# discover_kasa.py
# Comentario (ES): Descubre dispositivos Kasa en la LAN e imprime IP, modelo, MAC y alias.
import asyncio
from kasa import Discover

async def main():
    devices = await Discover.discover()
    if not devices:
        print("No Kasa devices found. Revisa que PC y bombillo estén en la misma red.")
    for ip, dev in devices.items():
        await dev.update()
        print(f"IP: {ip} | Model: {dev.model} | MAC: {dev.mac} | Alias: {dev.alias}")

asyncio.run(main())
