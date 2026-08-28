import Toybox.Graphics;
import Toybox.Lang;

module QrMatrixRenderer {
    const QR_SCREEN_FRACTION = 0.52;
    const TITLE_GAP = 0;
    const COUNTDOWN_GAP = 0;
    const QUIET_MODULES = 1;
    const COUNTDOWN_FONT = Graphics.FONT_XTINY;

    //! Title above QR — cached bitmap content (countdown drawn live each second).
    function drawContent(dc as Dc, matrix as Array<Array>, title as String) as Void {
        var layout = _layout(dc, matrix);
        if (layout == null) {
            return;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.clear();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            layout[:screenW] / 2,
            layout[:titleY],
            Graphics.FONT_SMALL,
            title,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        _drawModules(dc, matrix, layout);
    }

    function drawCountdown(dc as Dc, matrix as Array<Array>, seconds as Number) as Void {
        var layout = _layout(dc, matrix);
        if (layout == null) {
            return;
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            layout[:screenW] / 2,
            layout[:countdownY],
            COUNTDOWN_FONT,
            seconds.toString() + "s",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    function _layout(dc as Dc, matrix as Array<Array>) as Dictionary? {
        var modules = matrix.size();
        if (modules <= 0) {
            return null;
        }

        var screenW = dc.getWidth();
        var screenH = dc.getHeight();
        var titleFont = Graphics.FONT_SMALL;
        var titleHeight = Graphics.getFontHeight(titleFont);
        var countdownHeight = Graphics.getFontHeight(COUNTDOWN_FONT);
        var shorter = screenW < screenH ? screenW : screenH;
        var targetSize = (shorter * QR_SCREEN_FRACTION).toNumber();

        var moduleSize = targetSize / modules;
        if (moduleSize < 2) {
            moduleSize = 2;
        }

        var qrPixels = moduleSize * modules;
        var quiet = moduleSize * QUIET_MODULES;
        var block = qrPixels + (quiet * 2);
        var contentHeight = titleHeight + TITLE_GAP + block + COUNTDOWN_GAP + countdownHeight;
        var blockTop = (screenH - contentHeight) / 2;
        if (blockTop < 8) {
            blockTop = 8;
        }

        var titleY = blockTop;
        var originX = (screenW - qrPixels) / 2;
        var originY = blockTop + titleHeight + TITLE_GAP + quiet;
        var countdownY = originY + qrPixels + quiet + COUNTDOWN_GAP;

        return {
            :screenW => screenW,
            :titleY => titleY,
            :originX => originX,
            :originY => originY,
            :moduleSize => moduleSize,
            :qrPixels => qrPixels,
            :countdownY => countdownY,
        };
    }

    function _drawModules(dc as Dc, matrix as Array<Array>, layout as Dictionary) as Void {
        var modules = matrix.size();
        var originX = layout[:originX] as Number;
        var originY = layout[:originY] as Number;
        var moduleSize = layout[:moduleSize] as Number;

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
