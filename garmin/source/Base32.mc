import Toybox.Lang;

module Base32 {
    const ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";

    function decode(secretB32 as String) as ByteArray {
        var normalized = secretB32.toUpper();
        var length = normalized.length();
        var val = 0;
        var bits = 0;
        var temp = [] as Array<Number>;

        for (var i = 0; i < length; i += 1) {
            var ch = normalized.substring(i, i + 1);
            var idx = ALPHABET.find(ch);
            if (idx == null) {
                continue;
            }

            val = (val << 5) | idx;
            bits += 5;
            while (bits >= 8) {
                bits -= 8;
                temp.add((val >> bits) & 0xFF);
            }
        }

        var out = new [temp.size()]b;
        for (var j = 0; j < temp.size(); j += 1) {
            out[j] = temp[j];
        }
        return out;
    }
}
