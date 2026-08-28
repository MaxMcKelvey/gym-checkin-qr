# Gym QR

Personal check-in QR apps for **Garmin Forerunner 965** and phone. They generate the same rolling 15-character payload used by **A Fitness Club from LA**, so you can scan from your watch or phone.

```
@1 + rollingCode(4) + timeCounter(4) + memberSuffix(5)
```

Shared algorithm: [`docs/algorithm.md`](docs/algorithm.md)  
Credentials: [`docs/extract-credentials.md`](docs/extract-credentials.md)

| Path | What |
|------|------|
| `garmin/` | Connect IQ widget (FR965) — on-device QR |
| `phone/` | Expo / React Native companion |
| `docs/` | Payload spec, credential extraction, verify script |

---

## Quick start

### 1. Credentials

Extract your base32 secret and 5-character member suffix (see [`docs/extract-credentials.md`](docs/extract-credentials.md)). Keep them out of git (`docs/credentials.local.json` is ignored).

```bash
cp docs/credentials.example.json docs/credentials.local.json
# edit local file, then:
python3 docs/verify_payload.py --local
```

### 2. Garmin

1. Copy the example config and edit your credentials (file is gitignored):

   ```bash
   cp garmin/source/Config.mc.example garmin/source/Config.mc
   # edit Config.mc — set USE_FIXTURE = false and your secret + suffix
   ```

2. Build for `fr965` with the Connect IQ SDK / Monkey C extension.
3. Sideload `garmin.prg` to `Garmin/Apps` on the watch.
4. Optionally add the widget under **At a Glance**.

Details: [`garmin/README.md`](garmin/README.md)

### 3. Phone

```bash
cd phone && npm install && npm start
```

Enter the same credentials in **Settings**. Details: [`phone/README.md`](phone/README.md)

---

## License

This project is released under the **MIT License** — see [`LICENSE`](LICENSE).

### Third-party / cited sources

| Component | Source | License |
|-----------|--------|---------|
| On-device QR encoder (`garmin/source/qr/`) | [a-voronov/garmin-qr-code](https://github.com/a-voronov/garmin-qr-code) by Alexander Voronov | [MIT](garmin/source/qr/LICENSE) |
| HOTP dynamic truncation | [RFC 4226](https://datatracker.ietf.org/doc/html/rfc4226) | IETF |
| Base32 secret encoding | [RFC 4648](https://datatracker.ietf.org/doc/html/rfc4648) | IETF |
| Phone HMAC-SHA1 | [`@noble/hashes`](https://github.com/paulmillr/noble-hashes) | MIT |
| Phone QR rendering | [`react-native-qrcode-svg`](https://github.com/awesomejerry/react-native-qrcode-svg) | MIT |
| Phone base32 decode | [`hi-base32`](https://github.com/emn178/hi-base32) | MIT |

The Garmin QR package is vendored under `garmin/source/qr/` with its original MIT license file preserved. Modifications (byte-mode payloads, ECC L, single-mask path for watch performance) remain under that MIT grant; see [`garmin/source/qr/README.md`](garmin/source/qr/README.md).

---

## Security

- Do not commit real secrets, `credentials.local.json`, or `garmin/source/Config.mc`.
- This is for personal use on devices you own.
- Re-registering a device in the official app can invalidate an old seed — update both apps if that happens.
