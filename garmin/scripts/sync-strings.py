#!/usr/bin/env python3
"""Write resources/strings/strings.xml from Config.mc DISPLAY_NAME."""

from __future__ import annotations

import re
import sys
from pathlib import Path

GARMIN_DIR = Path(__file__).resolve().parents[1]
CONFIG = GARMIN_DIR / "source" / "Config.mc"
CONFIG_EXAMPLE = GARMIN_DIR / "source" / "Config.mc.example"
STRINGS = GARMIN_DIR / "resources" / "strings" / "strings.xml"

DEFAULT_NAME = "Gym"


def read_display_name() -> str:
    path = CONFIG if CONFIG.is_file() else CONFIG_EXAMPLE
    if not path.is_file():
        return DEFAULT_NAME

    match = re.search(r'const\s+DISPLAY_NAME\s*=\s*"([^"]*)"', path.read_text())
    if not match or not match.group(1).strip():
        return DEFAULT_NAME
    return match.group(1)


def main() -> int:
    name = read_display_name()
    escaped = (
        name.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )
    STRINGS.write_text(
        f"""<?xml version="1.0" encoding="UTF-8"?>
<strings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://developer.garmin.com/downloads/connect-iq/resources.xsd">
    <string id="AppName">{escaped}</string>
    <string id="Title">{escaped}</string>
    <string id="GlanceHint">Check-in code</string>
    <string id="Generating">Generating…</string>
    <string id="ConfigError">Set secret and 5-char suffix in Config.mc</string>
    <string id="BuildError">Could not build QR</string>
</strings>
""",
        encoding="utf-8",
    )
    print(f"strings.xml: AppName/Title = {name!r}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
