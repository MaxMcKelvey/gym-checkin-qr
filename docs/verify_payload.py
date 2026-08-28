#!/usr/bin/env python3
"""Reference implementation for docs/algorithm.md.

Public fixture tests use synthetic credentials (safe to commit).
Real credentials: copy credentials.example.json → credentials.local.json (gitignored)
or set GYM_SECRET / GYM_MEMBER_SUFFIX env vars.
"""

from __future__ import annotations

import hashlib
import hmac
import json
import os
import re
import struct
import sys
from datetime import datetime, timezone
from pathlib import Path

RADIX32 = "0123456789ABCDEFGHIJKLMNOPQRSTUV"
MEMBER_SUFFIX_RE = re.compile(r"^[0-9A-V]{1,5}$")

# Synthetic fixture — not a real gym account
FIXTURE_SECRET_B32 = "JBSWY3DPEHPK3PXP"
FIXTURE_MEMBER_SUFFIX = "BOOAE"
FIXTURE_KEY_HEX = "48656c6c6f21deadbeef"

FIXTURE_VECTORS = [
    (1767225600, "@18K480000BOOAE"),  # 2026-01-01 00:00:00 UTC, M=0
    (1767225659, "@18K480000BOOAE"),  # 2026-01-01 00:00:59 UTC, M=0
    (1767225660, "@1UD6A0001BOOAE"),  # 2026-01-01 00:01:00 UTC, M=1
    (1767229200, "@122DD001SBOOAE"),  # 2026-01-01 01:00:00 UTC, M=60
    (1798761600, "@18K480000BOOAE"),  # 2027-01-01 00:00:00 UTC, M=0 (year reset)
]

DOCS_DIR = Path(__file__).resolve().parent
LOCAL_CREDENTIALS = DOCS_DIR / "credentials.local.json"


def year_start_utc(unix_seconds: int) -> int:
    dt = datetime.fromtimestamp(unix_seconds, tz=timezone.utc)
    start = datetime(dt.year, 1, 1, tzinfo=timezone.utc)
    return int(start.timestamp())


def minute_counter(unix_seconds: int) -> int:
    return (unix_seconds - year_start_utc(unix_seconds)) // 60


def b32decode(s: str) -> bytes:
    s = s.upper().replace("=", "")
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
    val = bits = 0
    out = bytearray()
    for c in s:
        val = (val << 5) | alphabet.index(c)
        bits += 5
        while bits >= 8:
            bits -= 8
            out.append((val >> bits) & 0xFF)
    return bytes(out)


def to_radix32(n: int, width: int) -> str:
    if n < 0:
        raise ValueError(f"M must be non-negative, got {n}")
    s = ""
    x = n
    if x == 0:
        s = "0"
    while x:
        x, r = divmod(x, 32)
        s = RADIX32[r] + s
    return s.rjust(width, "0")


def normalize_member_suffix(value: str) -> str:
    suffix = value.strip().upper()
    if not MEMBER_SUFFIX_RE.match(suffix):
        raise ValueError("Member suffix must use radix-32 characters (0-9, A-V)")
    return suffix.rjust(5, "0")[-5:]


def build_payload(unix_seconds: int, key: bytes, member_suffix: str) -> str:
    m = minute_counter(unix_seconds)
    msg = struct.pack(">Q", m)
    digest = hmac.new(key, msg, hashlib.sha1).digest()
    off = digest[19] & 0x0F
    code = int.from_bytes(digest[off : off + 4], "big") & 0x7FFFFFFF
    rolling = to_radix32(code % 1_000_000, 4)
    counter = to_radix32(m, 4)
    member = normalize_member_suffix(member_suffix)
    return "@1" + rolling + counter + member


def _member_suffix_from_config(data: dict) -> str:
    if "memberSuffix" in data and data["memberSuffix"]:
        return normalize_member_suffix(str(data["memberSuffix"]))
    if "memberId" in data and data["memberId"]:
        return to_radix32(int(data["memberId"]), 5)
    raise ValueError("memberSuffix (5 chars) required in credentials")


def load_local_credentials() -> tuple[str, str]:
    if LOCAL_CREDENTIALS.is_file():
        data = json.loads(LOCAL_CREDENTIALS.read_text())
        secret = data["secretBase32"].strip()
        return secret, _member_suffix_from_config(data)

    secret = os.environ.get("GYM_SECRET", "").strip()
    suffix_raw = os.environ.get("GYM_MEMBER_SUFFIX", "").strip()
    if secret and suffix_raw:
        return secret, normalize_member_suffix(suffix_raw)

    raise SystemExit(
        "No local credentials. Copy docs/credentials.example.json to "
        "docs/credentials.local.json or set GYM_SECRET and "
        "GYM_MEMBER_SUFFIX."
    )


def run_fixture_tests() -> int:
    key = b32decode(FIXTURE_SECRET_B32)
    failed = 0

    if key.hex() != FIXTURE_KEY_HEX:
        print(f"FAIL key decode: {key.hex()} != {FIXTURE_KEY_HEX}")
        failed += 1

    if normalize_member_suffix("BOOAE") != FIXTURE_MEMBER_SUFFIX:
        print("FAIL member suffix normalize")
        failed += 1

    for ts, expected in FIXTURE_VECTORS:
        got = build_payload(ts, key, FIXTURE_MEMBER_SUFFIX)
        ok = got == expected
        print(f"{'OK' if ok else 'FAIL'}  ts={ts}  {got}")
        if not ok:
            print(f"      expected {expected}")
            failed += 1

    return failed


def main() -> int:
    if "--local" in sys.argv:
        secret, member_suffix = load_local_credentials()
        key = b32decode(secret)
        print(f"memberSuffix: {member_suffix}")
        print(f"key bytes ({len(key)}): {key.hex()}")
        if len(sys.argv) > 1 and sys.argv[-1].isdigit():
            ts = int(sys.argv[-1])
            print(f"payload @ {ts}: {build_payload(ts, key, member_suffix)}")
        return 0

    failed = run_fixture_tests()

    if len(sys.argv) > 1 and sys.argv[1].isdigit():
        ts = int(sys.argv[1])
        key = b32decode(FIXTURE_SECRET_B32)
        print(
            f"fixture payload @ {ts}: "
            f"{build_payload(ts, key, FIXTURE_MEMBER_SUFFIX)}"
        )

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
