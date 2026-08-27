# Extracting LA Fitness credentials

Your **base32 secret** and **member ID** come from the official LA Fitness Android app after device registration. Both the Garmin and phone apps read these values from local configuration — they are **not** in this repository.

This workflow uses a **Windows Android emulator** for login (headed UI) and **WSL only for the final `strings` step**. Run `adb` from **Windows PowerShell**, not WSL, so two adb servers do not fight over the device.

---

## Prerequisites

- Windows with Android Studio (bundles SDK, emulator, adb)
- WSL (optional, for `strings` on the pulled file)
- LA Fitness APK (e.g. from APKPure)

---

## 1. Install Android Studio

Install [Android Studio](https://developer.android.com/studio) on Windows if you do not already have it. It includes the SDK, emulator, and `adb`.

---

## 2. Create a rootable AVD

1. Open **Device Manager** → **Create Device**
2. Pick a phone profile (e.g. Pixel 6)
3. On the system image screen, choose an image whose **Services** column says **Google APIs**, **not Google Play**

   **Google APIs** images allow `adb root`. **Google Play** images do not.

4. Use a recent API level (34/35), **x86_64**. Modern images run ARM native libs via translation.

---

## 3. Launch the emulator

Click **▶** in Device Manager. A normal phone window opens — use it like a physical device for login.

---

## 4. Install the LA Fitness APK

**Easiest:** drag the APK onto the emulator window.

**Or from PowerShell:**

```powershell
cd $env:LOCALAPPDATA\Android\Sdk\platform-tools
.\adb install "C:\path\to\LA_Fitness_Mobile_LAF_1_267_APKPure.apk"
```

If install fails with a split-APK error, the download may be an XAPK — unzip it and run:

```powershell
.\adb install-multiple *.apk
```

A single universal APK usually works with plain `adb install`.

---

## 5. Sign in and trigger provisioning

1. Open LA Fitness on the emulator
2. Log in with your account
3. Open the membership card / check-in screen
4. Complete **device registration** if prompted

This step makes the server provision your check-in seed. Until registration finishes, `CheckinValues` will not exist.

**Heads-up:** registering a new device may deactivate check-in on your phone. You may need to re-register your phone afterward.

---

## 6. Root and pull `CheckinValues`

From **PowerShell** (same host as the emulator):

```powershell
cd $env:LOCALAPPDATA\Android\Sdk\platform-tools
.\adb root
.\adb shell ls -la /data/data/com.lafitness.lafitness/files/
.\adb pull /data/data/com.lafitness.lafitness/files/CheckinValues C:\temp\CheckinValues
```

`adb root` restarts `adbd` as root on Google APIs images so you can read app-private storage. Confirm `CheckinValues` appears in the `ls` output (alongside `CustomerBasic` and other files) before pulling.

---

## 7. Read fields with `strings` (WSL)

```bash
strings /mnt/c/temp/CheckinValues | less
```

The file is an **unencrypted serialized Java object** (`com.lafitness.app.CheckinValues`). Field names and string values show up as readable text.

### Example output (redacted)

```
 com.lafitness.app.CheckinValues2
CustomerIdI
MemberIdZ
ShowCheckinI
TimeDiffL
        SecretKeyt
Ljava/lang/String;L
Usernameq
YOUR_BASE32_SECRET_HERE
your_la_fitness_username
```

### What to extract

| Field | Where to find it | Notes |
|-------|------------------|-------|
| **SecretKey** | String after the `SecretKey` / type markers | RFC 4648 base32: uppercase **A–Z** and digits **2–7** only. No lowercase. No **0, 1, 8, or 9** — that distinguishes it from usernames and other text. |
| **Member suffix** | Last 5 chars of a known-good check-in QR | Radix-32 string (e.g. `O5TUJ`) — **not** visible as plain text in most `strings` dumps. Open the official app QR and copy the last 5 characters once your secret validates. |
| **Username** | Near end of dump | Account login name — not used in the QR algorithm. |

Copy the secret and member suffix into local config (see below). **Do not commit them to git.**

---

## 8. Local configuration

Copy the example file and fill in your values:

```bash
cp docs/credentials.example.json docs/credentials.local.json
```

```json
{
  "secretBase32": "YOUR_BASE32_SECRET_HERE",
  "memberSuffix": "O5TUJ",
  "username": "your_la_fitness_username"
}
```

`docs/credentials.local.json` is gitignored. Use it with:

```bash
python3 docs/verify_payload.py --local
```

Wire the same values into the phone app **Settings** screen or the Garmin `Config` module when implementing the watch side.

---

## Fallbacks

| Problem | Alternative |
|---------|-------------|
| Login or registration fails (emulator detection) | Use a **real rooted device** and the same `adb pull` path |
| `strings` output is too messy to parse | **Frida** on the same emulator: hook `com.lib.totp.TotpGenerator.<init>(String)` — the seed is printed at construction with no file parsing |
| Unsure the secret is correct | Validate against captured QR payloads from the official app at known timestamps (see algorithm doc) |

---

## Validation

After extraction:

1. Run `python3 docs/verify_payload.py --local` to print the current payload
2. Compare against a QR/code shown by the official app at the same UTC minute
3. Once confirmed, implement the same secret and member ID on Garmin (`garmin/`) and phone (`phone/`)

See [`algorithm.md`](algorithm.md) for the full payload specification.
