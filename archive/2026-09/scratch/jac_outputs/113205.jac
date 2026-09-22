"""Calculate the Julian Day from a (year, month, day, hour, minute, second, microsecond) tuple"""
def _julian_day(dt: Any) -> object {
    (yr, mo, dy, hr, mn, sc, us) = dt;
    if (mo <= 2) {
        mo += 12;
        yr -= 1;
    }
    dy = (
        dy
        + (hr / 24.0)
        + (mn / (24.0 * 60.0))
        + (sc / (24.0 * 60.0 * 60.0))
        + (us / (24.0 * 60.0 * 60.0 * 1000000.0))
    );
    a = int((yr / 100));
    b = (2 - a) + int((a / 4));
    jd = (int((365.25 * (yr + 4716))) + int((30.6001 * (mo + 1))) + dy + b) - 1524.5;
    return jd;
}