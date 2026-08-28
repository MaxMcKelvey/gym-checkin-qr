# Garmin app — Gym QR

Connect IQ **widget** for Forerunner 965. Shows a check-in QR for **A Fitness Club from LA** with a configurable title under the code (default **Gym**).

**Algorithm:** [`../docs/algorithm.md`](../docs/algorithm.md)  
**Credentials:** [`../docs/extract-credentials.md`](../docs/extract-credentials.md)

---

## Configuration (`source/Config.mc`)

`Config.mc` is **gitignored**. Copy the example once, then edit locally:

```bash
cp source/Config.mc.example source/Config.mc
```

| Constant | Purpose |
|----------|---------|
| `DISPLAY_NAME` | Label under the QR, glance tile, and watch launcher name. Default `"Gym"` if empty. Example: `"LA Fitness"`. |
| `SECRET_B32` | Base32 TOTP secret from `CheckinValues` |
| `MEMBER_SUFFIX` | Last 5 chars of your check-in code (radix-32) |
| `USE_FIXTURE` | `true` = skip credential validation; still uses `SECRET_B32` / `MEMBER_SUFFIX` below |

---

## Build and sideload

Every build has two steps: **sync strings**, then **compile**.

### 1. Sync launcher strings

`DISPLAY_NAME` lives in Monkey C (`Config.mc`), but the watch launcher reads `resources/strings/strings.xml` at compile time. Run the sync script before each build so both match:

```bash
python3 scripts/sync-strings.py
```

This writes `AppName` and `Title` in `strings.xml` from `Config.mc` (falls back to `Config.mc.example`, then `"Gym"`).

### 2. Compile

**VS Code:** open the `garmin/` folder, use **Monkey C: Build for Device** (run sync first if you changed `DISPLAY_NAME`).

**CLI** (from repo root):

```bash
python3 garmin/scripts/sync-strings.py

java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true \
  -jar "$CONNECTIQ_SDK/bin/monkeybrains.jar" \
  -o garmin/garmin.prg \
  -f garmin/monkey.jungle \
  -y ~/garmin-dev/developer_key \
  -d fr965 -w -r
```

Set `CONNECTIQ_SDK` to your SDK path, e.g.  
`~/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.2.0-…`

### 3. Sideload

1. Plug in the watch via USB.
2. Copy `garmin/garmin.prg` → `Garmin/Apps/` on the watch volume.
3. Eject — the file may disappear from Finder after eject (normal).
4. Optional: add the widget under **At a Glance** in watch settings.

---

## UI

- QR encodes the **15-character payload only** (not the title).
- Black modules on white; ECC **L**, binary mode (payload contains `@`).
- Bezel ring shows progress through the current minute (updates ~20×/sec).
- Next minute’s QR is pre-built in the background for a seamless swap at `:00`.

### Display while open

While the QR screen is visible, the app pulses `Attention.backlight()` at full brightness to resist wrist-away dimming. **AMOLED limits apply:** Garmin caps programmatic backlight time (~1 minute) and cannot keep the panel at full brightness indefinitely (burn-in protection). For longer sessions at the scanner, also set the watch **Settings → System → Backlight** timeout as high as allowed, or tap the screen if it dims.

---

## Module layout

```
garmin/
├── scripts/sync-strings.py    # Config.mc DISPLAY_NAME → strings.xml
├── manifest.xml
├── monkey.jungle
├── source/
│   ├── Config.mc.example      # Copy → Config.mc (gitignored)
│   ├── GymQrApp.mc
│   ├── GymQrView.mc
│   ├── GymQrGlanceView.mc
│   ├── PayloadGenerator.mc
│   ├── RefreshRingRenderer.mc
│   ├── QrMatrixRenderer.mc
│   └── qr/                    # On-device QR encoder (MIT)
└── resources/strings/strings.xml
```

---

## QR encoder license

On-device encoding is adapted from [garmin-qr-code](https://github.com/a-voronov/garmin-qr-code) (Alexander Voronov, **MIT**). License: [`source/qr/LICENSE`](source/qr/LICENSE).

---

## Checklist

- [ ] `Config.mc` with real secret, suffix, and `DISPLAY_NAME`
- [ ] `python3 scripts/sync-strings.py` before each build
- [ ] `USE_FIXTURE = false` before gym use
- [ ] Live compare vs official app at the same UTC minute
- [ ] Sideload test at the gym scanner
