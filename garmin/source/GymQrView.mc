import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

class GymQrView extends WatchUi.View {

    enum DisplayState {
        CONFIG_ERROR,
        BUILDING,
        READY,
        BUILD_ERROR
    }

    enum BuildTarget {
        DISPLAY,
        PENDING
    }

    private const TICK_MS = 1000;

    private var mState as DisplayState = BUILDING;
    private var mDisplayMatrix as Array<Array>? = null;
    private var mDisplayMinute as Number = -1;
    private var mPendingMatrix as Array<Array>? = null;
    private var mPendingMinute as Number = -1;
    private var mBuilder as QRCodeBuilder? = null;
    private var mBuildTarget as BuildTarget = DISPLAY;
    private var mBuildMinute as Number = -1;
    private var mTimer as Timer.Timer? = null;

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        if (mTimer == null) {
            mTimer = new Timer.Timer();
            mTimer.start(method(:onTick), TICK_MS, true);
        }
        DisplayKeepAwake.onViewShown();
        _ensureDisplayForMinute(_currentMinute(), true);
    }

    function onHide() as Void {
        DisplayKeepAwake.onViewHidden();
        if (mTimer != null) {
            mTimer.stop();
            mTimer = null;
        }
        QrContentCache.invalidate();
        _stopBuilder();
    }

    function onTick() as Void {
        DisplayKeepAwake.pulse();

        if (!PayloadGenerator.isConfigured()) {
            if (mState != CONFIG_ERROR) {
                mState = CONFIG_ERROR;
            }
            WatchUi.requestUpdate();
            return;
        }

        _handleMinuteRollover();
        _schedulePendingBuild();
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        if (mState == READY && mDisplayMatrix != null) {
            var title = Config.displayName();
            QrContentCache.ensure(dc, mDisplayMatrix, title);
            QrContentCache.blit(dc);
            QrMatrixRenderer.drawCountdown(dc, mDisplayMatrix, _secondsUntilRefresh());
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

    private function _secondsUntilRefresh() as Number {
        var sec = Time.now().value() % 60;
        if (sec < 0) {
            sec += 60;
        }
        var remaining = 60 - sec;
        return remaining > 0 ? remaining : 60;
    }

    private function _currentMinute() as Number {
        return PayloadGenerator.minuteCounter(Time.now().value());
    }

    private function _handleMinuteRollover() as Void {
        var minute = _currentMinute();
        if (minute == mDisplayMinute) {
            return;
        }

        if (mPendingMatrix != null && mPendingMinute == minute) {
            _promotePending();
            return;
        }

        if (mBuilder != null && mBuildTarget == PENDING && mBuildMinute == minute) {
            return;
        }

        _ensureDisplayForMinute(minute, false);
    }

    private function _promotePending() as Void {
        mDisplayMatrix = mPendingMatrix;
        mDisplayMinute = mPendingMinute;
        mPendingMatrix = null;
        mPendingMinute = -1;
        mState = READY;
        QrContentCache.invalidate();
        _schedulePendingBuild();
    }

    private function _ensureDisplayForMinute(minute as Number, force as Boolean) as Void {
        if (!PayloadGenerator.isConfigured()) {
            mState = CONFIG_ERROR;
            return;
        }

        if (!force && minute == mDisplayMinute && mDisplayMatrix != null) {
            return;
        }

        if (mBuilder != null && mBuildTarget == DISPLAY && mBuildMinute == minute) {
            return;
        }

        _startBuild(minute, DISPLAY);
    }

    private function _schedulePendingBuild() as Void {
        if (mState != READY || mDisplayMinute < 0) {
            return;
        }

        var nextMinute = mDisplayMinute + 1;
        if (mPendingMatrix != null && mPendingMinute == nextMinute) {
            return;
        }
        if (mBuilder != null && mBuildTarget == PENDING && mBuildMinute == nextMinute) {
            return;
        }

        _startBuild(nextMinute, PENDING);
    }

    private function _startBuild(minute as Number, target as BuildTarget) as Void {
        if (target == DISPLAY) {
            if (mBuilder != null) {
                if (mBuildTarget == PENDING && mBuildMinute == minute) {
                    return;
                }
                _stopBuilder();
            }
            if (mDisplayMatrix == null) {
                mState = BUILDING;
            }
        } else if (mBuilder != null) {
            return;
        }

        mBuildTarget = target;
        var now = Time.now().value();
        var targetUnix = target == PENDING
            ? YearTime.nextMinuteUnix(now)
            : YearTime.unixForMinute(minute, now);
        mBuildMinute = PayloadGenerator.minuteCounter(targetUnix);

        var payload = PayloadGenerator.buildAt(targetUnix);
        mBuilder = new QRCodeBuilder(payload, QRCodeBuilder.L);
        mBuilder.subscribe(weak(), :onBuilderStatus);
        var error = mBuilder.start();
        if (error != null) {
            if (target == DISPLAY) {
                mState = BUILD_ERROR;
            }
            _stopBuilder();
        }
    }

    function onBuilderStatus(args as { :status as QRCodeBuilder.Status, :payload as Lang.Object }) as Void {
        if (args[:status] != QRCodeBuilder.FINISHED) {
            return;
        }

        var payload = args[:payload];
        var matrix = null as Array<Array>?;
        if (payload instanceof Array) {
            matrix = payload as Array<Array>;
        }

        var target = mBuildTarget;
        var minute = mBuildMinute;
        _stopBuilder();

        if (matrix == null) {
            if (target == DISPLAY) {
                mState = BUILD_ERROR;
            }
            return;
        }

        if (target == DISPLAY) {
            mDisplayMatrix = matrix;
            mDisplayMinute = minute;
            mState = READY;
            QrContentCache.invalidate();
            _schedulePendingBuild();
        } else {
            mPendingMatrix = matrix;
            mPendingMinute = minute;
            if (_currentMinute() == minute && mDisplayMinute != minute) {
                _promotePending();
            }
        }
    }

    private function _stopBuilder() as Void {
        if (mBuilder != null) {
            mBuilder.stop();
            mBuilder = null;
        }
        mBuildMinute = -1;
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
