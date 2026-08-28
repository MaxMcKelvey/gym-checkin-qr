import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Minute countdown ring along the watch bezel (12 o'clock, clockwise).
module RefreshRingRenderer {
    const PEN_WIDTH = 12;
    const INSET = 4;
    const ARC_START = 90; // 12 o'clock (Garmin: 0 = 3 o'clock, CCW)

    function progressInMinute(unixSeconds as Number) as Float {
        return progressInMinuteSmooth(unixSeconds, 0.0);
    }

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
        var cap = PEN_WIDTH / 2;

        dc.setPenWidth(PEN_WIDTH);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, ARC_START, ARC_START);
        _drawCap(dc, cx, cy, r, ARC_START, Graphics.COLOR_LT_GRAY, cap);

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
            _drawCap(dc, cx, cy, r, ARC_START, Graphics.COLOR_BLACK, cap);
            return;
        }

        var endAngle = ARC_START - sweep;
        dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, ARC_START, endAngle);
        _drawCap(dc, cx, cy, r, ARC_START, Graphics.COLOR_BLACK, cap);
        _drawCap(dc, cx, cy, r, endAngle, Graphics.COLOR_BLACK, cap);
    }

    function _drawCap(dc as Dc, cx as Number, cy as Number, r as Number, degrees as Number, color as Number, cap as Number) as Void {
        var pt = _pointOnRing(cx, cy, r, degrees);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(pt[0], pt[1], cap);
    }

    //! Garmin degrees: 0 = 3 o'clock, increasing CCW.
    function _pointOnRing(cx as Number, cy as Number, r as Number, degrees as Number) as [Number, Number] {
        var rad = degrees * Math.PI / 180.0;
        var x = (cx + r * Math.cos(rad)).toNumber();
        var y = (cy - r * Math.sin(rad)).toNumber();
        return [x, y];
    }
}
