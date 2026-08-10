import time;

"""
Convert UTC seconds to GPS seconds.
"""
def utc_to_gps(utcsec: int) -> int {
    def seconds(year: int, month: int, day: int) -> float {
        return time.mktime((year, month, day, 0, 0, 0, 0, 0, 0)) - time.timezone;
    }
    kUTCGPSOffset0 = (10 * 365 + 7) * 24 * 3600;
    kLeapSecondList = (
        (seconds(1981, 7, 1), 1),
        (seconds(1982, 7, 1), 2),
        (seconds(1983, 7, 1), 3),
        (seconds(1985, 7, 1), 4),
        (seconds(1988, 1, 1), 5),
        (seconds(1990, 1, 1), 6),
        (seconds(1991, 1, 1), 7),
        (seconds(1992, 7, 1), 8),
        (seconds(1993, 7, 1), 9),
        (seconds(1994, 7, 1), 10),
        (seconds(1996, 1, 1), 11),
        (seconds(1997, 7, 1), 12),
        (seconds(1999, 1, 1), 13),
        (seconds(2006, 1, 1), 14),
        (seconds(2009, 1, 1), 15),
        (seconds(2012, 7, 1), 16),
        (seconds(2015, 7, 1), 17),
        (seconds(2017, 1, 1), 18)
    );
    leapSeconds = 0;
    for x in reversed(kLeapSecondList) {
        if utcsec >= x[0] {
            leapSeconds = x[1];
            break;
        }
    }
    return utcsec - kUTCGPSOffset0 + leapSeconds;
}