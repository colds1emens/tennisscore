#!/usr/bin/env python3
"""Минимальный клиент App Store Connect API.

Конфиг (Key ID / Issuer ID / путь к .p8) читается из
AppStore/private/asc_config.json — этот каталог в .gitignore, секреты не
попадают в репозиторий. Сам скрипт секретов не содержит.

Использование:
    python3 scripts/asc.py get /v1/apps
    python3 scripts/asc.py get "/v1/apps?filter[bundleId]=com.efremov.tennisscore"
    python3 scripts/asc.py post /v1/apps '<json>'
    python3 scripts/asc.py patch /v1/.../id '<json>'
    python3 scripts/asc.py token        # напечатать свежий JWT (для altool)
"""

import base64
import json
import os
import subprocess
import sys
import time

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature

BASE = "https://api.appstoreconnect.apple.com"
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def load_config() -> dict:
    path = os.path.join(REPO, "AppStore", "private", "asc_config.json")
    with open(path) as f:
        cfg = json.load(f)
    cfg["p8"] = os.path.join(REPO, cfg["p8"]) if not os.path.isabs(cfg["p8"]) else cfg["p8"]
    return cfg


def make_token(cfg: dict) -> str:
    with open(cfg["p8"], "rb") as f:
        private_key = serialization.load_pem_private_key(f.read(), password=None)
    header = {"alg": "ES256", "kid": cfg["key_id"], "typ": "JWT"}
    now = int(time.time())
    payload = {
        "iss": cfg["issuer_id"],
        "iat": now,
        "exp": now + 1100,
        "aud": "appstoreconnect-v1",
    }
    signing_input = (
        _b64url(json.dumps(header, separators=(",", ":")).encode())
        + "."
        + _b64url(json.dumps(payload, separators=(",", ":")).encode())
    )
    der = private_key.sign(signing_input.encode(), ec.ECDSA(hashes.SHA256()))
    r, s = decode_dss_signature(der)
    raw = r.to_bytes(32, "big") + s.to_bytes(32, "big")
    return signing_input + "." + _b64url(raw)


def request(method: str, path: str, token: str, body: dict | None = None):
    """HTTP через curl (берёт системные сертификаты macOS — у Python.framework
    своего бандла нет). Возвращает (status, json)."""
    url = path if path.startswith("http") else BASE + path
    cmd = [
        "curl", "-s", "-S", "-X", method,
        "-H", f"Authorization: Bearer {token}",
        "-w", "\n%{http_code}",
        url,
    ]
    if body is not None:
        cmd[1:1] = ["-H", "Content-Type: application/json", "-d", json.dumps(body)]
    out = subprocess.run(cmd, capture_output=True, text=True).stdout
    newline = out.rfind("\n")
    text, code = out[:newline], out[newline + 1:].strip()
    status = int(code) if code.isdigit() else 0
    try:
        return status, (json.loads(text) if text.strip() else {})
    except json.JSONDecodeError:
        return status, {"raw": text}


def main() -> int:
    cfg = load_config()
    token = make_token(cfg)

    if len(sys.argv) < 2:
        print(__doc__)
        return 1

    cmd = sys.argv[1]
    if cmd == "token":
        print(token)
        return 0

    method = cmd.upper()
    path = sys.argv[2]
    body = json.loads(sys.argv[3]) if len(sys.argv) > 3 else None
    status, payload = request(method, path, token, body)
    print(f"HTTP {status}")
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if status < 400 else 2


if __name__ == "__main__":
    sys.exit(main())
