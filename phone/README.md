# Phone app — LA Fitness QR

React Native **Expo** app with **NativeWind (Tailwind)**. Displays a rotating LA Fitness check-in QR code that matches the Garmin watch app and [`../docs/algorithm.md`](../docs/algorithm.md).

## Features

- 15-character payload QR (`@1` + rolling code + time counter + member ID)
- Refreshes every minute (1-second timer detects UTC minute rollover)
- Settings screen (gear icon, top right) for base32 secret and member ID
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

Matches the four reference vectors in `docs/algorithm.md`.

## Configuration

1. Tap the **settings gear** (top right).
2. Enter your **base32 secret** (RFC 4648, no padding).
3. Enter your **member ID** (decimal registration number).
4. Save — the QR updates immediately and rolls over each UTC minute.

Do not commit real secrets to git.

## Stack

- Expo SDK 57 + expo-router
- NativeWind 4 + Tailwind CSS
- `@noble/hashes` (HMAC-SHA1)
- `hi-base32` (secret decode)
- `react-native-qrcode-svg` (QR render)
