"""Convert sexigisimal-formatted string/integer to a decimal degree value."""
def sex_to_dec(s: int | str) -> float {
    s = format(int(s), '07d');
    (degree, arcmin, arcsec) = (s[:3], s[3:5], s[5:]);
    float(degree) + float(arcmin) / 60 + float(arcsec) / 3600
}