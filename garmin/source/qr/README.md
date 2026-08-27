# QR encoder (on-device)

Adapted from [garmin-qr-code](https://github.com/a-voronov/garmin-qr-code) by Andrey Voronov (MIT License).

Modified for byte-mode payloads (`@1…` check-in codes) and LA Fitness QR rendering via `QrMatrixRenderer.mc`.

The Forerunner 965 does not expose Garmin's Connect IQ 9 `Toybox.ScanCode` API, so QR modules are drawn with `Graphics.Dc.fillRectangle` after matrix generation.
