import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class LaFitnessQrApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new $.LaFitnessQrView(), new $.LaFitnessQrDelegate()];
    }

    //! Required for At a Glance on FR965 / CIQ 4+ ("super apps").
    function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        return [new $.LaFitnessQrGlanceView()];
    }
}

function log(msg as String) as Void {
    // Hot-path logging (especially matrix dumps) is far too slow on-device.
    // Uncomment for simulator debugging only:
    // System.println(msg);
}
