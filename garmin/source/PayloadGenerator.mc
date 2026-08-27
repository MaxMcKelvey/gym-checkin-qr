import Toybox.Lang;
import Toybox.Time;

module PayloadGenerator {
    const MEMBER_SUFFIX_LENGTH = 5;

    function minuteCounter(unixSeconds as Number) as Number {
        return (unixSeconds - Constants.EPOCH) / 60;
    }

    function toRadix32(value as Number, width as Number) as String {
        if (value < 0) {
            return "00000".substring(0, width);
        }

        var digits = "";
        var n = value;
        if (n == 0) {
            digits = "0";
        }
        while (n > 0) {
            var remainder = n % 32;
            n = n / 32;
            digits = Constants.RADIX32.substring(remainder, remainder + 1) + digits;
        }

        while (digits.length() < width) {
            digits = "0" + digits;
        }
        return digits;
    }

    function normalizeMemberSuffix(value as String) as String {
        var suffix = value.toUpper();
        while (suffix.length() < MEMBER_SUFFIX_LENGTH) {
            suffix = "0" + suffix;
        }
        if (suffix.length() > MEMBER_SUFFIX_LENGTH) {
            suffix = suffix.substring(suffix.length() - MEMBER_SUFFIX_LENGTH, suffix.length());
        }
        return suffix;
    }

    function isValidMemberSuffix(value as String) as Boolean {
        if (value.length() != MEMBER_SUFFIX_LENGTH) {
            return false;
        }
        for (var i = 0; i < MEMBER_SUFFIX_LENGTH; i += 1) {
            if (Constants.RADIX32.find(value.substring(i, i + 1)) == null) {
                return false;
            }
        }
        return true;
    }

    function packMinuteBE(minute as Number) as ByteArray {
        var bytes = new [8]b;
        var value = minute;
        for (var i = 7; i >= 0; i -= 1) {
            bytes[i] = (value & 0xFF).toNumber();
            value = value / 256;
        }
        return bytes;
    }

    function build(unixSeconds as Number, key as ByteArray, memberSuffix as String) as String {
        var minute = minuteCounter(unixSeconds);
        if (minute < 0) {
            return "@1INVALID00000000".substring(0, 15);
        }

        var member = normalizeMemberSuffix(memberSuffix);
        var digest = HmacSha1.compute(key, packMinuteBE(minute));
        var offset = digest[19] & 0x0F;
        var binary =
            ((digest[offset] & 0x7F) << 24) |
            (digest[offset + 1] << 16) |
            (digest[offset + 2] << 8) |
            digest[offset + 3];
        var rolling = toRadix32(binary % 1000000, 4);
        var counter = toRadix32(minute, 4);

        return "@1" + rolling + counter + member;
    }

    function buildNow() as String {
        var key = Base32.decode(Config.SECRET_B32);
        return build(Time.now().value(), key, Config.MEMBER_SUFFIX);
    }

    function isConfigured() as Boolean {
        if (Config.USE_FIXTURE) {
            return true;
        }
        return Config.SECRET_B32.length() > 0
            && isValidMemberSuffix(normalizeMemberSuffix(Config.MEMBER_SUFFIX));
    }
}
