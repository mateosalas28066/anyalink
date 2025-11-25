# hs_login_test.py
# Comentario (ES): Login explícito a un Kasa (HS300/KL..), luego lista hijos.

import asyncio
import os
import sys

from kasa import Credentials, Discover


async def main(ip: str):
  email = os.environ.get("KASA_EMAIL")
  password = os.environ.get("KASA_PASSWORD")
  if not email or not password:
    raise RuntimeError("Define KASA_EMAIL y KASA_PASSWORD en el entorno.")

  creds = Credentials(email, password)

  dev = await Discover.discover_single(ip)
  # Autenticación local (KLAP) con tus credenciales de Kasa
  await dev.login(creds)

  # Ya autenticado, actualiza y muestra info
  await dev.update()
  print(
      f"Conectado: ip={ip} model={getattr(dev,'model','?')} alias={getattr(dev,'alias','?')}"
  )
  children = getattr(dev, "children", [])
  if children:
    for i, ch in enumerate(children):
      await ch.update()
      print(
          f"[{i}] alias={getattr(ch,'alias','?')} is_on={getattr(ch,'is_on',None)}"
      )
  else:
    print("Sin hijos (no es regleta o no expone children).")


if __name__ == "__main__":
  if len(sys.argv) != 2:
    print("Uso: python hs_login_test.py <IP_HS300>")
    sys.exit(1)
  asyncio.run(main(sys.argv[1]))
