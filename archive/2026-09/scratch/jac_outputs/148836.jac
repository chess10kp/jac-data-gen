glob EPOCH_JD = 2451545;
glob DAYS_PER_JULIAN_CENTURY = 36525;

"""Returns the Julian Century with Julian Day, julian_local."""
def julian_century(jd_local: float) -> float {
    days_century = EPOCH_JD;
    for i in range(EPOCH_JD, 0, -DAYS_PER_JULIAN_CENTURY) {
        if jd_local < i {
            days_century = i - DAYS_PER_JULIAN_CENTURY;
        } else {
            break;
        }
    }
    return (jd_local - days_century) / DAYS_PER_JULIAN_CENTURY;
}