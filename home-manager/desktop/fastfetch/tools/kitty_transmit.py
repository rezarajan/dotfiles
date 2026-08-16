#!/usr/bin/env python3
"""Transmit a PNG to the terminal via the kitty graphics protocol.

Usage: kitty_transmit.py <image-id> <png-path>

Sends the file base64-encoded in 4096-byte chunks with a=t (transmit
only, no display) and q=2 (never respond), so the greeting can later
flip frames with cheap a=p placement escapes. Writing to stdout is fine:
the caller runs us with stdout on the tty.
"""
import base64
import sys

image_id = int(sys.argv[1])
payload = base64.standard_b64encode(open(sys.argv[2], "rb").read())

first = True
out = sys.stdout.buffer
while payload or first:
    chunk, payload = payload[:4096], payload[4096:]
    ctrl = f"m={1 if payload else 0}"
    if first:
        ctrl = f"a=t,f=100,i={image_id},q=2," + ctrl
        first = False
    out.write(b"\033_G" + ctrl.encode() + b";" + chunk + b"\033\\")
out.flush()
