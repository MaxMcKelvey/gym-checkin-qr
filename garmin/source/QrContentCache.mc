import Toybox.Graphics;
import Toybox.Lang;

//! Caches QR + title in a bitmap so the ring can animate without redrawing modules.
module QrContentCache {
    var mBitmap as Graphics.BufferedBitmap? = null;
    var mMatrixRef as Array<Array>? = null;
    var mTitle as String? = null;

    function invalidate() as Void {
        mBitmap = null;
        mMatrixRef = null;
        mTitle = null;
    }

    function ensure(dc as Dc, matrix as Array<Array>, title as String) as Void {
        if (mBitmap != null && mMatrixRef == matrix && mTitle != null && mTitle.equals(title)) {
            return;
        }

        var w = dc.getWidth();
        var h = dc.getHeight();
        var bitmap = _createBitmap(w, h);
        if (bitmap == null) {
            return;
        }

        var bdc = bitmap.getDc();
        QrMatrixRenderer.drawContent(bdc, matrix, title);
        mBitmap = bitmap;
        mMatrixRef = matrix;
        mTitle = title;
    }

    function blit(dc as Dc) as Void {
        if (mBitmap != null) {
            dc.drawBitmap(0, 0, mBitmap);
        }
    }

    function _createBitmap(width as Number, height as Number) as Graphics.BufferedBitmap? {
        var opts = {
            :width => width,
            :height => height,
        };

        if (Graphics has :createBufferedBitmap) {
            var ref = Graphics.createBufferedBitmap(opts);
            return ref.get();
        }

        return new Graphics.BufferedBitmap(opts);
    }
}
