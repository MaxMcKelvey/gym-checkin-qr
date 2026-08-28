import Toybox.Graphics;
import Toybox.Lang;

module QrMatrixRenderer {
    const QR_SCREEN_FRACTION = 0.52;

    //! QR code and title only (no bezel ring). Used for bitmap caching.
    function drawContent(dc as Dc, matrix as Array<Array>, title as String) as Void {
        var modules = matrix.size();
        if (modules <= 0) {
            return;
        }

        var screenW = dc.getWidth();
        var screenH = dc.getHeight();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.clear();

        var titleFont = Graphics.FONT_SMALL;
        var titleHeight = Graphics.getFontHeight(titleFont) + 12;
        var shorter = screenW < screenH ? screenW : screenH;
        var targetSize = (shorter * QR_SCREEN_FRACTION).toNumber();

        var moduleSize = targetSize / modules;
        if (moduleSize < 2) {
            moduleSize = 2;
        }

        var qrPixels = moduleSize * modules;
        var quiet = moduleSize * 2;
        var block = qrPixels + (quiet * 2);
        var originX = (screenW - qrPixels) / 2;
        var contentHeight = block + titleHeight;
        var blockTop = (screenH - contentHeight) / 2;
        if (blockTop < 8) {
            blockTop = 8;
        }
        var originY = blockTop + quiet;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        for (var row = 0; row < modules; row += 1) {
            var line = matrix[row];
            for (var col = 0; col < line.size(); col += 1) {
                if (_isDark(line[col])) {
                    dc.fillRectangle(
                        originX + (col * moduleSize),
                        originY + (row * moduleSize),
                        moduleSize,
                        moduleSize
                    );
                }
            }
        }

        dc.drawText(
            screenW / 2,
            originY + qrPixels + quiet + 6,
            titleFont,
            title,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    function draw(dc as Dc, matrix as Array<Array>, title as String, refreshProgress as Float?) as Void {
        drawContent(dc, matrix, title);
        if (refreshProgress != null) {
            RefreshRingRenderer.draw(dc, refreshProgress);
        }
    }

    function _isDark(cell as Lang.Object) as Boolean {
        if (cell instanceof Lang.Number) {
            return (cell as Number) == 1;
        }
        if (cell instanceof Lang.Char) {
            return (cell as Char) == '1';
        }
        if (cell instanceof Lang.String) {
            return (cell as String).equals("1");
        }
        return false;
    }
}
