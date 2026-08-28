import Toybox.Attention;
import Toybox.Lang;

//! Best-effort keep display awake while the QR view is visible.
//!
//! On AMOLED watches (including FR965), Garmin limits programmatic backlight
//! time (~1 minute cumulative) to prevent burn-in. Wrist-away dimming may still
//! occur depending on system settings. This pulses the backlight while open.
module DisplayKeepAwake {
    const ENABLED = true;
    const BRIGHTNESS = 1.0;

    var mActive as Boolean = false;
    var mSuppressed as Boolean = false;

    function onViewShown() as Void {
        mActive = true;
        mSuppressed = false;
        pulse();
    }

    function onViewHidden() as Void {
        mActive = false;
    }

    function pulse() as Void {
        if (!ENABLED || !mActive || mSuppressed) {
            return;
        }
        if (!(Attention has :backlight)) {
            return;
        }
        try {
            Attention.backlight(BRIGHTNESS);
        } catch (e) {
            mSuppressed = true;
        }
    }
}
