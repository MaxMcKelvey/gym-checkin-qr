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
}

function log(msg as String) as Void {
    System.println(msg);
}
