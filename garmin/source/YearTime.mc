import Toybox.Lang;
import Toybox.Time;

//! UTC calendar helpers for the check-in time counter.
module YearTime {
    function startOfYearUtc(unixSeconds as Number) as Number {
        var year = Time.Gregorian.utcInfo(new Time.Moment(unixSeconds), Time.FORMAT_SHORT).year;
        var days = 0;
        for (var y = 1970; y < year; y += 1) {
            days += _isLeapYear(y) ? 366 : 365;
        }
        return days * 86400;
    }

    function nextMinuteUnix(unixSeconds as Number) as Number {
        var yearStart = startOfYearUtc(unixSeconds);
        var minute = (unixSeconds - yearStart) / 60;
        return yearStart + ((minute + 1) * 60);
    }

    function unixForMinute(minute as Number, referenceUnix as Number) as Number {
        return startOfYearUtc(referenceUnix) + (minute * 60);
    }

    function _isLeapYear(year as Number) as Boolean {
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    }
}
