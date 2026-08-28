import Toybox.Graphics;
import Toybox.Lang;

//! Minute countdown ring along the watch bezel (12 o'clock, clockwise).
module RefreshRingRenderer {
    const PEN_WIDTH = 6;
    const INSET = 3;
    const ARC_START = 90; // 12 o'clock

    function progressInMinute(unixSeconds as Number) as Float {
        return progressInMinuteSmooth(unixSeconds, 0.0);
    }

    //! Sub-second progress: unix second + fraction within [0, 1).
    function progressInMinuteSmooth(unixSeconds as Number, secondFraction as Float) as Float {
        var sec = unixSeconds % 60;
        if (sec < 0) {
            sec += 60;
        }
        var frac = secondFraction;
        if (frac < 0.0) {
            frac = 0.0;
        } else if (frac >= 1.0) {
            frac = 0.999;
        }
        var progress = (sec + frac) / 60.0;
        if (progress > 1.0) {
            progress = 1.0;
        }
        return progress;
    }

    function draw(dc as Dc, progress as Float) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;
        var half = w < h ? w : h;
        var r = half / 2 - INSET - PEN_WIDTH / 2;

        dc.setPenWidth(PEN_WIDTH);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, ARC_START, ARC_START);

        var clamped = progress;
        if (clamped < 0.0) {
            clamped = 0.0;
        } else if (clamped > 1.0) {
            clamped = 1.0;
        }

        var sweep = (clamped * 360.0).toNumber();
        if (sweep <= 0) {
            return;
        }

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        if (sweep >= 359) {
            dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, ARC_START, ARC_START);
            return;
        }

        dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, ARC_START, ARC_START - sweep);
    }
}
