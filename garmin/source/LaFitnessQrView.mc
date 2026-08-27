import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

class LaFitnessQrView extends WatchUi.View {

    enum DisplayState {
        CONFIG_ERROR,
        BUILDING,
        READY,
        BUILD_ERROR
    }

    private var mState as DisplayState = BUILDING;
    private var mPayload as String = "";
    private var mMatrix as Array<Array>? = null;
    private var mBuilder as QRCodeBuilder? = null;
    private var mLastMinute as Number = -1;
    private var mTimer as Timer.Timer? = null;

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        if (mTimer == null) {
            mTimer = new Timer.Timer();
            mTimer.start(method(:onTick), 1000, true);
        }
        refreshIfNeeded(true);
    }

    function onHide() as Void {
        if (mTimer != null) {
            mTimer.stop();
            mTimer = null;
        }
        stopBuilder();
    }

    function onTick() as Void {
        refreshIfNeeded(false);
    }

    function onUpdate(dc as Dc) as Void {
        if (mState == READY && mMatrix != null) {
            QrMatrixRenderer.draw(
                dc,
                mMatrix,
                WatchUi.loadResource(Rez.Strings.Title)
            );
            return;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.clear();

        if (mState == CONFIG_ERROR) {
            _drawMessage(dc, WatchUi.loadResource(Rez.Strings.ConfigError));
            return;
        }

        if (mState == BUILD_ERROR) {
            _drawMessage(dc, WatchUi.loadResource(Rez.Strings.BuildError));
            return;
        }

        _drawMessage(dc, WatchUi.loadResource(Rez.Strings.Generating));
    }

    private function refreshIfNeeded(force as Boolean) as Void {
        if (!PayloadGenerator.isConfigured()) {
            mState = CONFIG_ERROR;
            WatchUi.requestUpdate();
            return;
        }

        var minute = PayloadGenerator.minuteCounter(Time.now().value());
        // Don't restart while a build is already in progress — the 1s timer
        // was resetting the encoder every tick and leaving "Generating..." forever.
        if (!force && (mState == BUILDING || (minute == mLastMinute && mMatrix != null))) {
            return;
        }

        mLastMinute = minute;
        mPayload = PayloadGenerator.buildNow();
        startBuilder();
    }

    private function startBuilder() as Void {
        stopBuilder();
        mMatrix = null;
        mState = BUILDING;
        WatchUi.requestUpdate();

        mBuilder = new QRCodeBuilder(mPayload, QRCodeBuilder.L);
        mBuilder.subscribe(weak(), :onBuilderStatus);
        var error = mBuilder.start();
        if (error != null) {
            mState = BUILD_ERROR;
            WatchUi.requestUpdate();
        }
    }

    function onBuilderStatus(args as { :status as QRCodeBuilder.Status, :payload as Lang.Object }) as Void {
        var status = args[:status];
        var payload = args[:payload];

        if (status == QRCodeBuilder.FINISHED) {
            if (payload instanceof Lang.Number) {
                mState = BUILD_ERROR;
            } else if (payload instanceof Array) {
                mMatrix = payload as Array<Array>;
                mState = READY;
            } else {
                mState = BUILD_ERROR;
            }
            WatchUi.requestUpdate();
        }
    }

    private function stopBuilder() as Void {
        if (mBuilder != null) {
            mBuilder.stop();
            mBuilder = null;
        }
    }

    private function _drawMessage(dc as Dc, message as String) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2,
            Graphics.FONT_MEDIUM,
            message,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
}
