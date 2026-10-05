#!/usr/bin/env python3
"""echo.py -- a tiny line-echo server for testing netcat: a banner, then
"YOU SAID: <line>" for every line received.   python3 emu/echo.py [port]"""
import socketserver, sys

class Echo(socketserver.StreamRequestHandler):
    def handle(self):
        self.wfile.write(b"WELCOME TO THE NETCAT TEST\r\nSERVER. TYPE A LINE AND\r\nPRESS START TO SEND IT.\r\n\r\n")
        for raw in self.rfile:
            line = raw.decode("ascii", "replace").strip()
            self.wfile.write(b"YOU SAID: " + line.encode() + b"\r\n")

socketserver.ThreadingTCPServer.allow_reuse_address = True
port = int(sys.argv[1]) if len(sys.argv) > 1 else 7777
with socketserver.ThreadingTCPServer(("127.0.0.1", port), Echo) as srv:
    srv.serve_forever()
