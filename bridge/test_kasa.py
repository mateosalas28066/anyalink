# test_kasa.py
# Comentario (ES): Prueba control local del bombillo Kasa por IP.
import asyncio
from kasa import SmartBulb

IP = "192.168.0.19"  # <- tu IP

async def main():
    bulb = SmartBulb(IP)
    await bulb.update()
    print("is_on:", bulb.is_on)
    if bulb.is_on:
        await bulb.turn_off(); print("turned OFF")
    else:
        await bulb.turn_on();  print("turned ON")
    await bulb.update()
    print("now:", bulb.is_on)

asyncio.run(main())
