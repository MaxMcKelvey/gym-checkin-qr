# QR encoder (on-device)

Adapted from [garmin-qr-code](https://github.com/a-voronov/garmin-qr-code) by Alexander Voronov.

**License:** MIT — see [`LICENSE`](LICENSE) (Copyright (c) 2021 Alexander Voronov).

Modified for byte-mode payloads (`@1…` check-in codes) and Gym QR rendering via `QrMatrixRenderer.mc`.

The Forerunner 965 does not expose Garmin's Connect IQ 9 `Toybox.ScanCode` API, so QR modules are drawn with `Graphics.Dc.fillRectangle` after matrix generation.
