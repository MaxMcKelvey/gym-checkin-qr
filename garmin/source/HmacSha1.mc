import Toybox.Cryptography;
import Toybox.Lang;

module HmacSha1 {
    const BLOCK_SIZE = 64;

    function compute(key as ByteArray, message as ByteArray) as ByteArray {
        if (key.size() > BLOCK_SIZE) {
            var keyHash = new Cryptography.Hash({ :algorithm => Cryptography.HASH_SHA1 });
            keyHash.update(key);
            key = keyHash.digest();
        }

        var ipad = new [BLOCK_SIZE]b;
        var opad = new [BLOCK_SIZE]b;

        for (var i = 0; i < BLOCK_SIZE; i += 1) {
            var kb = i < key.size() ? key[i] : 0;
            ipad[i] = (kb ^ 0x36).toNumber();
            opad[i] = (kb ^ 0x5C).toNumber();
        }

        var inner = new Cryptography.Hash({ :algorithm => Cryptography.HASH_SHA1 });
        inner.update(ipad);
        inner.update(message);
        var innerDigest = inner.digest();

        var outer = new Cryptography.Hash({ :algorithm => Cryptography.HASH_SHA1 });
        outer.update(opad);
        outer.update(innerDigest);
        return outer.digest();
    }
}
