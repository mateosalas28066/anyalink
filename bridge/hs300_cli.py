# hs300_cli.py
# Comentario (ES): CLI para HS300 (TP-Link). Usa discover_single con credenciales KLAP.
# Lista hijos y permite encender/apagar por alias o índice.

import argparse
import asyncio
import os
import sys

from kasa import Credentials, Discover


async def get_device(ip: str, creds: Credentials):
  dev = await Discover.discover_single(ip, credentials=creds, discovery_timeout=8)
  if dev is None:
    raise RuntimeError(f"No device discovered at {ip}")
  await dev.update()
  return dev


async def list_children(dev):
  children = getattr(dev, "children", [])
  rows = []
  for i, ch in enumerate(children):
    await ch.update()
    rows.append(
        (
            i,
            getattr(ch, "alias", "") or f"child_{i}",
            bool(getattr(ch, "is_on", False)),
        )
    )
  return rows


async def set_child_state(
    dev,
    *,
    alias: str | None,
    index: int | None,
    state: bool,
):
  children = getattr(dev, "children", [])
  if not children:
    raise RuntimeError("No child plugs found.")

  target = None
  if alias is not None:
    for ch in children:
      if (getattr(ch, "alias", "") or "").lower() == alias.lower():
        target = ch
        break
    if target is None:
      raise RuntimeError(f"Child alias '{alias}' not found.")
  else:
    if index is None or index < 0 or index >= len(children):
      raise RuntimeError(f"Index out of range 0..{len(children) - 1}.")
    target = children[index]

  await target.update()
  if state:
    await target.turn_on()
  else:
    await target.turn_off()
  await target.update()
  return getattr(target, "alias", f"child_{index}"), bool(getattr(target, "is_on", False))


async def main():
  parser = argparse.ArgumentParser(description="TP-Link HS300 CLI")
  parser.add_argument("ip", help="HS300 IP address (e.g., 192.168.0.42)")

  sub = parser.add_subparsers(dest="cmd", required=True)
  sub.add_parser("list", help="List child plugs")

  p_on = sub.add_parser("on", help="Turn ON a child by alias or index")
  p_on.add_argument("--alias", help="Exact child alias as in Kasa app")
  p_on.add_argument("--index", type=int, help="Child index (0-based)")

  p_off = sub.add_parser("off", help="Turn OFF a child by alias or index")
  p_off.add_argument("--alias", help="Exact child alias as in Kasa app")
  p_off.add_argument("--index", type=int, help="Child index (0-based)")

  args = parser.parse_args()

  email = os.environ.get("KASA_EMAIL")
  password = os.environ.get("KASA_PASSWORD")
  if not email or not password:
    print("Set KASA_EMAIL and KASA_PASSWORD environment variables first.")
    sys.exit(2)
  creds = Credentials(email, password)

  dev = await get_device(args.ip, creds)
  print(
      f"Connected: ip={args.ip} model={getattr(dev,'model','?')} alias={getattr(dev,'alias','?')} mac={getattr(dev,'mac','?')}"
  )

  if args.cmd == "list":
    rows = await list_children(dev)
    if not rows:
      print("No child plugs.")
    for i, alias, state in rows:
      print(f"[{i}] alias={alias} is_on={state}")
    return

  if args.cmd in ("on", "off"):
    if (args.alias is None) == (args.index is None):
      print("Provide exactly one of --alias or --index")
      sys.exit(3)
    want = args.cmd == "on"
    alias, state = await set_child_state(
        dev, alias=args.alias, index=args.index, state=want
    )
    print(f"OK: {alias} -> is_on={state}")


if __name__ == "__main__":
  asyncio.run(main())
