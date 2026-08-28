# Garmin app — Gym QR

Connect IQ **widget** for Forerunner 965. Shows a check-in QR for **A Fitness Club from LA** plus a **“Gym”** title under the code.

**Algorithm:** [`../docs/algorithm.md`](../docs/algorithm.md)  
**Credentials:** [`../docs/extract-credentials.md`](../docs/extract-credentials.md)

---

## Overview

| Piece | Approach | Notes |
|-------|----------|-------|
| Payload (`@1` + TOTP + counter + suffix) | Monkey C | See algorithm doc |
| Base32 decode | `Base32.mc` | No Connect IQ API |
| HMAC-SHA1 | `HmacSha1.mc` via `Toybox.Cryptography.Hash` | Built-in HMAC is SHA-256 only |
| QR image | Vendored MIT encoder (`source/qr/`) + `QrMatrixRenderer` | FR965 lacks `Toybox.ScanCode` |
| UI | `WatchUi.View` + timer | QR centered, “Gym” label; refresh on minute boundary |

**Device:** FR965 — 454×454 AMOLED round display.

---

## Module layout

```
garmin/
├── manifest.xml
├── monkey.jungle
├── source/
│   ├── Config.mc.example      # Copy → Config.mc (gitignored)
│   ├── GymQrApp.mc
│   ├── GymQrView.mc           # QR + title + minute refresh
│   ├── GymQrGlanceView.mc     # At a Glance
│   ├── GymQrDelegate.mc
│   ├── PayloadGenerator.mc
│   ├── Base32.mc
│   ├── HmacSha1.mc
│   ├── Constants.mc
│   ├── QrMatrixRenderer.mc
│   └── qr/                    # On-device QR encoder (MIT)
└── resources/
    └── strings/strings.xml
```

Copy the example config, then add your credentials from [`../docs/extract-credentials.md`](../docs/extract-credentials.md):

```bash
cp source/Config.mc.example source/Config.mc
# edit Config.mc — set USE_FIXTURE = false and your secret + suffix
```

`Config.mc` is gitignored.

---

## UI

```
┌─────────────────────┐
│                     │
│    ┌───────────┐    │
│    │  QR CODE  │    │
│    └───────────┘    │
│                     │
│        Gym          │
│                     │
└─────────────────────┘
```

- QR encodes the **15-character payload only**.
- Black modules on white; ECC **L**, binary mode (payload contains `@`).

---

## QR encoder license

On-device encoding is adapted from [garmin-qr-code](https://github.com/a-voronov/garmin-qr-code) (Alexander Voronov, **MIT**). License copy: [`source/qr/LICENSE`](source/qr/LICENSE).

---

## Build and sideload

1. Open `garmin/` in VS Code with the Monkey C extension.
2. Download **fr965** in SDK Manager.
3. Build for device → copy `.prg` to `Garmin/Apps` on the watch (USB).
4. Add under **At a Glance** if you want the glance tile.

```bash
java -jar "$CONNECTIQ_SDK/bin/monkeybrains.jar" \
  -o garmin/garmin.prg -f garmin/monkey.jungle \
  -y ~/garmin-dev/developer_key -d fr965 -w -r
```

---

## Checklist

- [x] Base32, HMAC-SHA1, payload generator
- [x] On-device QR + minute refresh + glance
- [ ] Real credentials in `Config.mc` (`USE_FIXTURE = false`)
- [ ] Live compare vs official app at the same UTC minute
- [ ] Sideload test at the gym scanner
