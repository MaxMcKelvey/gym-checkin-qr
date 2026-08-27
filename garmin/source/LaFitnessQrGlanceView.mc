import Toybox.Graphics;
import Toybox.WatchUi;

//! Compact At a Glance preview — keep this light (no QR encode).
class LaFitnessQrGlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            0,
            h / 2 - Graphics.getFontHeight(Graphics.FONT_SMALL) / 2 - 2,
            Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.Title),
            Graphics.TEXT_JUSTIFY_LEFT
        );
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            0,
            h / 2 + 4,
            Graphics.FONT_TINY,
            WatchUi.loadResource(Rez.Strings.GlanceHint),
            Graphics.TEXT_JUSTIFY_LEFT
        );
    }
}
