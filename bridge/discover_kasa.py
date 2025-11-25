# discover_kasa.py
import asyncio
import getpass
import os

from kasa import Discover, Credentials

EMAIL = os.environ.get("KASA_EMAIL") or input("mateosalas28@hotmail.com").strip()
PASSWORD = os.environ.get("KASA_PASSWORD") or getpass.getpass("superyespa123")

creds = Credentials(EMAIL, PASSWORD)

async def main():
    devices = await Discover.discover()
    if not devices:
        print("No Kasa devices found. Revisa que PC y bombillo estén en la misma red.")
        return

    for ip, dev in devices.items():
        await dev.update(credentials=creds)
        print(f"IP: {ip} | Model: {dev.model} | MAC: {dev.mac} | Alias: {dev.alias}")

asyncio.run(main())
