# Phone app — Gym QR

React Native **Expo** app with **NativeWind (Tailwind)**. Displays a rotating check-in QR that matches the Garmin watch app and [`../docs/algorithm.md`](../docs/algorithm.md) (payload used by **A Fitness Club from LA**).

## Features

- 15-character payload QR (`@1` + rolling code + time counter + member suffix)
- Refreshes every minute (UTC minute boundary)
- Settings for base32 secret and member suffix
- Credentials stored locally via AsyncStorage

## Run

```bash
cd phone
npm install
npm start
```

Then open in Expo Go (iOS/Android) or a simulator.

## Verify algorithm

```bash
npm run test:payload
```

Matches the reference vectors in `docs/algorithm.md`.

## Configuration

1. Tap the **settings gear**.
2. Enter your **base32 secret** (RFC 4648, no padding).
3. Enter your **member suffix** (5 radix-32 chars).
4. Save — the QR updates immediately.

Do not commit real secrets to git. Extraction guide: [`../docs/extract-credentials.md`](../docs/extract-credentials.md).

## Stack / attribution

- Expo SDK + expo-router
- NativeWind 4 + Tailwind CSS
- [`@noble/hashes`](https://github.com/paulmillr/noble-hashes) (HMAC-SHA1, MIT)
- [`hi-base32`](https://github.com/emn178/hi-base32) (secret decode, MIT)
- [`react-native-qrcode-svg`](https://github.com/awesomejerry/react-native-qrcode-svg) (QR render, MIT)
