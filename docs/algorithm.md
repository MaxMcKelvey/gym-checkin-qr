# Gym check-in code — algorithm

This document is the **shared specification** for generating the check-in payload used by **A Fitness Club from LA**. Both the Garmin watch app (`garmin/`) and the phone app (`phone/`, React Native Expo) must implement the same logic so they produce identical codes at the same moment.

The scanner at the gym reads a **QR code** whose content is the 15-character payload string below. The UI label **“Gym”** is display-only and is **not** encoded in the QR.

---

## Payload format

At any instant, build a string:

```
@1 + rollingCode + timeCounter + memberId
```

| Field | Length | Description |
|-------|--------|-------------|
| Prefix | 2 | Literal `@1` |
| Rolling code | 4 | TOTP-style code for the current minute |
| Time counter | 4 | Minute index `M` (see below), radix-32 |
| Member suffix | 5 | Static registration ID, radix-32 (e.g. `O5TUJ`) |

**Total length: 15 characters.**

All encoded fields use the same **radix-32 alphabet** (case-sensitive):

```
0123456789ABCDEFGHIJKLMNOPQRSTUV
```

Radix-32 encoding: repeated division by 32, map remainder to alphabet character, build digits least-significant first, then **left-pad with `0`** to the required width.

---

## Time base

All time math uses **UTC**. The minute counter resets at the start of each calendar year.

```
yearStart = unixSeconds of Jan 1 00:00:00 UTC for the current year
M = floor((unixSeconds - yearStart) / 60)
```

`M` is the number of whole minutes since **January 1 UTC of the same calendar year** as `unixSeconds`. The rolling code and time counter both derive from the same `M` for a given moment.

Within a minute, `M` is constant — e.g. `00:00:00` through `00:00:59` UTC on New Year's Day all use `M = 0`. On `2027-01-01 00:00:00 UTC`, `M` resets to `0` again (it does not continue counting from the previous year).

---

## Secret key

The TOTP secret is stored by **A Fitness Club from LA**'s app as **RFC 4648 base32** (no padding). Extract it from the Android app's `CheckinValues` file — see [`extract-credentials.md`](extract-credentials.md).

After base32 decode you get a **10-byte** HMAC key.

Store the secret in local config only (`docs/credentials.local.json`, app settings, or Garmin `Config.mc`). **Never commit it to git.**

---

## Rolling code (4 chars)

Standard HOTP/TOTP-style computation with **HMAC-SHA1** and **dynamic truncation** (RFC 4226).

### Step 1 — Counter message

Encode `M` as an **8-byte big-endian unsigned integer** (64-bit):

```
message = M as uint64 big-endian   // 8 bytes
```

### Step 2 — HMAC-SHA1

```
digest = HMAC_SHA1(key, message)   // 20 bytes
```

### Step 3 — Dynamic truncation

```
offset = digest[19] & 0x0F
binary = (4 bytes from digest[offset .. offset+3], big-endian) & 0x7FFFFFFF
code   = binary % 1_000_000
```

### Step 4 — Encode

```
rollingCode = toRadix32(code, 4)   // left-pad to 4 chars
```

---

## Time counter (4 chars)

```
timeCounter = toRadix32(M, 4)      // left-pad to 4 chars
```

---

## Member suffix (5 chars)

The last five characters of every check-in payload — a **radix-32 string** you configure directly (not a decimal number):

```
memberSuffix = "O5TUJ"   // exactly 5 chars, alphabet 0-9A-V
```

This is the same value as the last 5 characters of a known-good QR from the official app. If you only have the decimal ID internally, convert with `toRadix32(decimal, 5)` — but storing the 5-char suffix is enough.

If the account is re-registered, this value may change; both apps must use the same suffix.

---

## Full assembly

```
payload = "@1" + rollingCode + timeCounter + memberId
```

Generate a **QR code** from `payload` (the raw string, no URL wrapper unless the club expects one — use the 15-char string as-is unless testing proves otherwise).

---

## Reference test vectors

The repo includes a **synthetic public fixture** (not a real account) so tests can run without your credentials:

| UTC timestamp | `M` | Payload (fixture) |
|---------------|-----|-------------------|
| 2026-01-01 00:00:00 | 0 | `@18K480000BOOAE` |
| 2026-01-01 00:00:59 | 0 | `@18K480000BOOAE` |
| 2026-01-01 00:01:00 | 1 | `@1UD6A0001BOOAE` |
| 2026-01-01 01:00:00 | 60 | `@122DD001SBOOAE` |
| 2027-01-01 00:00:00 | 0 | `@18K480000BOOAE` |

Fixture secret: `JBSWY3DPEHPK3PXP` · fixture member suffix: `BOOAE`

```bash
python3 docs/verify_payload.py          # run fixture tests
python3 docs/verify_payload.py --local  # print payload with your credentials.local.json
```

After extracting your real secret and member ID, validate against QR codes from the official app at known timestamps before deploying to a watch.

---

## Refresh behavior

- Recompute `payload` when the minute rolls over (`M` changes).
- While still in the same minute, the payload is unchanged.
- Watch and phone should use **system UTC time**; large clock skew will produce invalid codes.

---

## Phone app

The `phone/` app (React Native Expo + NativeWind) implements this spec. Credentials are entered in Settings after extraction. Run `npm run test:payload` in `phone/` to verify against the public fixture vectors.

---

## Credentials

See [`extract-credentials.md`](extract-credentials.md) for pulling `SecretKey` and `MemberId` from **A Fitness Club from LA**'s Android app via emulator + adb.

---

## Security notes

- The base32 secret is equivalent to a gym membership credential. Do not commit it to public repositories.
- This spec was reverse-engineered for personal use on owned devices.
- Rotating secrets or member IDs requires updating configuration in both apps.
