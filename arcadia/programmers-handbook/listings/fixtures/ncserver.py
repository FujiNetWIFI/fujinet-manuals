#!/usr/bin/env python3
"""ncserver.py -- the line server the netcat chapter talks to.

On connect it greets with NETCAT SAYS HI (16 columns), then answers every line with
ECHO and the line in capitals. BYE closes. Everything it hears goes to the
log, so a test can see what the Studio II sent.

    python3 ncserver.py PORT LOGFILE
"""
import asyncio
import sys
import time

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8767
LOG = sys.argv[2] if len(sys.argv) > 2 else "ncserver.log.txt"


def log(msg):
    with open(LOG, "a") as f:
        f.write(time.strftime("%H:%M:%S ") + msg + "\n")


async def client(reader, writer):
    peer = writer.get_extra_info("peername")
    log("connect %s" % (peer,))
    await asyncio.sleep(0.5)
    writer.write(b"NETCAT SAYS HI\r\n")
    await writer.drain()
    try:
        while True:
            line = await reader.readline()
            if not line:
                break
            text = line.decode("ascii", "replace").rstrip("\r\n")
            log("heard %r" % text)
            if text.strip().upper() == "BYE":
                writer.write(b"BYE\r\n")
                await writer.drain()
                break
            writer.write(("ECHO " + text.upper() + "\r\n").encode("ascii", "replace"))
            await writer.drain()
    finally:
        log("close %s" % (peer,))
        writer.close()


async def main():
    server = await asyncio.start_server(client, "127.0.0.1", PORT)
    log("listening on %d" % PORT)
    async with server:
        await server.serve_forever()


asyncio.run(main())
