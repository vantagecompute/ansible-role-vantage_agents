#!/usr/bin/env python3
"""A stand-in for the Keycloak token endpoint and the Vantage artifact CDN.

It lets the role's Ansible logic run on a throwaway VM without a real cluster.
It proves only that logic: the real systemd-setup, token and binaries are not
involved. Real verification needs a VM from the Vantage image and a real
cluster.

Usage: stub_cdn.py PORT
Serves:
  POST /realms/vantage/protocol/openid-connect/token  -> {"access_token": "stub-token"}
  GET  /binaries/<name>/linux-amd64/<version>/<name>          the stub binary
  GET  /binaries/<name>/linux-amd64/<version>/<name>.sha256   its checksum
Every GET needs "Authorization: Bearer stub-token", as the real CDN does.
"""
import hashlib
import json
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer

TOKEN = "stub-token"

# What a stub binary does. systemd-setup imitates the real one closely enough
# for the role: user, directories, /usr/bin copy and units. Any other argument
# is the service itself, which just waits.
STUB = """#!/bin/sh
# stub {name}, build {build}
name={name}
case "${{1:-}}" in
systemd-setup)
  id -u "$name" >/dev/null 2>&1 || useradd --system --user-group --no-create-home --shell /usr/sbin/nologin "$name"
  install -d -m 0750 -o "$name" -g "$name" "/var/lib/$name"
  install -d -m 0755 /etc/vantage
  case "$name" in
    slurm-accounts-reconciler) install -d -m 0750 -o root -g "$name" "/etc/vantage/$name" ;;
    vref-agent) install -d -m 0750 -o root -g "$name" "/etc/vantage/$name" ;;
    *) install -d -m 0700 "/etc/vantage/$name" ;;
  esac
  install -m 0755 "$0" "/usr/bin/$name"
  if [ "$name" = vref-agent ]; then
    cat > /etc/systemd/system/vref-agent.service <<UNIT
[Unit]
Description=stub vref-agent
ConditionPathExists=/etc/vantage/vref-agent/env
[Service]
Type=oneshot
ExecStart=/usr/bin/vref-agent run
UNIT
    cat > /etc/systemd/system/vref-agent.timer <<UNIT
[Unit]
Description=stub vref-agent timer
[Timer]
OnUnitActiveSec=10s
OnBootSec=10s
[Install]
WantedBy=timers.target
UNIT
    cat > /etc/systemd/system/vref-agent.path <<UNIT
[Unit]
Description=stub vref-agent path
[Path]
PathExists=/run/vref-agent/wake
[Install]
WantedBy=multi-user.target
UNIT
    systemctl daemon-reload
    systemctl enable vref-agent.timer vref-agent.path
  else
    cat > "/etc/systemd/system/$name.service" <<UNIT
[Unit]
Description=stub $name
ConditionPathExists=/etc/vantage/$name/env
[Service]
User=$name
EnvironmentFile=/etc/vantage/$name/env
ExecStart=/usr/bin/$name run
Restart=always
[Install]
WantedBy=multi-user.target
UNIT
    systemctl daemon-reload
    systemctl enable "$name.service"
  fi
  ;;
*) exec sleep 3600 ;;
esac
"""


def binary_for(name: str, version: str) -> bytes:
    return STUB.format(name=name, build=version).encode()


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):  # keep test output quiet
        pass

    def _send(self, code, body, ctype="application/octet-stream"):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        if self.path == "/realms/vantage/protocol/openid-connect/token":
            self.rfile.read(int(self.headers.get("Content-Length", 0)))
            self._send(200, json.dumps({"access_token": TOKEN}).encode(), "application/json")
        else:
            self._send(404, b"")

    def do_GET(self):
        if self.headers.get("Authorization") != f"Bearer {TOKEN}":
            return self._send(401, b"")
        parts = self.path.strip("/").split("/")
        if len(parts) != 5 or parts[0] != "binaries" or parts[2] != "linux-amd64":
            return self._send(404, b"")
        _, name, _, version, filename = parts
        data = binary_for(name, version)
        if filename == name:
            return self._send(200, data)
        if filename == name + ".sha256":
            digest = hashlib.sha256(data).hexdigest()
            return self._send(200, f"{digest}  {name}\n".encode(), "text/plain")
        self._send(404, b"")


if __name__ == "__main__":
    HTTPServer(("127.0.0.1", int(sys.argv[1])), Handler).serve_forever()
