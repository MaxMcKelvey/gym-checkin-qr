# Garmin app — LA Fitness QR

Connect IQ **watch-app** for Forerunner 965 (and optionally other devices later). Shows a QR code for LA Fitness check-in plus an **“LA Fitness”** title under the code.

**Algorithm:** [`../docs/algorithm.md`](../docs/algorithm.md)  
**Credentials:** [`../docs/extract-credentials.md`](../docs/extract-credentials.md)

---

## Is this doable?

**Yes**, with two non-trivial pieces on Garmin:

| Piece | Approach | Notes |
|-------|----------|-------|
| Payload (`@1` + TOTP + counter + ID) | Implement in Monkey C | Straightforward math; see algorithm doc |
| Base32 decode | Small Monkey C helper | No Connect IQ API; ~20 lines |
| HMAC-SHA1 | Manual HMAC using `Toybox.Cryptography.Hash` | Built-in `HashBasedMessageAuthenticationCode` only supports **SHA-256**; SHA-1 hash exists but HMAC-SHA1 must be composed manually (ipad/opad + Hash) or ported |
| QR image | On-device matrix encoder (`source/qr/`, MIT) + `QrMatrixRenderer` | FR965 lacks Connect IQ 9 `ScanCode`; modules drawn with `fillRectangle` |
| UI | `WatchUi.View` + timer | QR centered, “LA Fitness” label below; refresh on minute boundary |

**Device:** FR965 — 454×454 AMOLED round display; plenty of room for a ~280–320 px QR and title.

---

## Connect IQ / API considerations

### ScanCode (QR generation)

Garmin added native QR generation in **Connect IQ 6.0**:

```monkeyc
import Toybox.ScanCode;
import Toybox.Graphics;

// Runtime guard — required for devices/simulators on older CIQ
if (Toybox has :ScanCode) {
    var bitmap = ScanCode.createQrCodeImage(
        payload,                          // 15-char String
        ScanCode.QR_CODE_ECC_MEDIUM,
        qrSize,                           // e.g. 280
        {
            :color => Graphics.COLOR_BLACK,
            :backgroundColor => Graphics.COLOR_WHITE
        }
    );
    dc.drawBitmap(x, y, bitmap);
}
```

- Set `minApiLevel` to **6.0.0** in `manifest.xml` if ScanCode is required with no fallback.
- SDK device files for FR965 may still list simulator CIQ **5.2**; the **physical watch** may run CIQ 6.x after a firmware update. Always use `Toybox has :ScanCode` if you need to support both.
- **Simulator:** ScanCode may not appear until device files match production CIQ 6.x. Plan to test QR on a **real FR965** via sideload early.

### HMAC-SHA1

```monkeyc
import Toybox.Cryptography;

var hash = new Cryptography.Hash({ :algorithm => Cryptography.HASH_SHA1 });
// HMAC = H( (key xor opad) || H( (key xor ipad) || message ) )
// Block size for SHA-1: 64 bytes; key is 10 bytes — pad with zeros to 64
```

Port a minimal HMAC-SHA1 helper once and unit-test against [`../docs/algorithm.md`](../docs/algorithm.md) test vectors.

### Time

```monkeyc
import Toybox.Time;
import Toybox.System;

var now = Time.now();           // Time.Moment
var info = Time.Gregorian.info(now, Time.FORMAT_SHORT);
// Prefer unix seconds if available on target API; else compute from Gregorian UTC
```

Use **UTC** for `M`. Confirm `System.getTimer()` vs calendar APIs — `Time.now()` + UTC conversion is the usual pattern.

### Refresh timer

- On view show: compute payload, generate QR bitmap, request update.
- Start a 1-second `Timer.Timer` to detect minute rollover (`M` change) and regenerate.
- Optionally redraw at 59s to prep for rollover.

---

## Planned module layout

```
garmin/
├── manifest.xml
├── monkey.jungle
├── Config.example.mc
├── source/
│   ├── Config.mc              # Credentials (edit before gym use)
│   ├── LaFitnessQrApp.mc
│   ├── LaFitnessQrView.mc     # QR + title + minute refresh
│   ├── PayloadGenerator.mc
│   ├── Base32.mc
│   ├── HmacSha1.mc
│   ├── Constants.mc
│   ├── QrMatrixRenderer.mc
│   └── qr/                    # On-device QR encoder (MIT, see README)
└── resources/
    └── strings/strings.xml
```

Configuration (secret, member ID) comes from [`../docs/extract-credentials.md`](../docs/extract-credentials.md). Store locally in:

1. **Connect IQ app settings** (requires store submission or `.SET` sideload file), or
2. **Constants in source** for personal sideload-only use (simplest for v1) — e.g. `Config.mc`, gitignored or never pushed.

---

## UI spec

```
┌─────────────────────┐
│                     │
│    ┌───────────┐    │
│    │           │    │
│    │  QR CODE  │    │   ← ScanCode bitmap, white background
│    │           │    │
│    └───────────┘    │
│                     │
│    LA Fitness       │   ← Graphics.FONT_SMALL/MEDIUM, centered
│                     │
└─────────────────────┘
```

- QR encodes the **15-character payload only** (not the title).
- Black modules on white background for reliable scanning.
- ECC: `QR_CODE_ECC_MEDIUM` is a good default for a short numeric/alphanumeric string.

---

## Build and sideload

1. Open `garmin/` in VS Code with the Monkey C extension.
2. **Monkey C: Verify Installation**
3. Download **fr965** device in SDK Manager (if not already).
4. Generate developer key on first build.
5. Run simulator (payload logic) or **Monkey C: Build for Device** → copy `.prg` to `GARMIN/APPS/` on the watch.

No Connect IQ Store publish required for personal use.

---

## Implementation checklist

- [x] `Base32.decode()` → byte key
- [x] `HmacSha1.compute(key, message)` → 20-byte digest
- [x] `PayloadGenerator.build(unixSeconds)` → 15-char string
- [x] On-device QR matrix generation + draw (FR965)
- [x] Minute-boundary timer refresh
- [ ] Set real credentials in `source/Config.mc` (`USE_FIXTURE = false`)
- [ ] Validate one live payload against official app QR at same UTC minute
- [ ] Sideload test at gym scanner (final acceptance)

---

## Permissions

Current manifest has empty permissions — correct for offline QR (no BLE, comms, or position needed).

If CIQ 6 ScanCode is unavailable on your firmware, document the CIQ version from **Settings → About → Connect IQ** on the watch before investing in a custom QR encoder.
