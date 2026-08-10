"""Convert a declination string to degrees."""
def PDMS2Dec(decst: str, sep: str = ":") -> float {
    pp = decst.split(sep);
    if len(pp) > 0 {
        deg = int(pp[0]);
    } else {
        deg = 0;
    }
    if len(pp) > 1 {
        min = int(pp[1]);
    } else {
        min = 0;
    }
    if len(pp) > 2 {
        ssec = float(pp[2]);
    } else {
        ssec = 0.0;
    }
    dec = float(abs(deg)) + (float(min) / 60.0) + (ssec / 3600.0);
    if pp[0].find("-") >= 0 {
        dec = -dec;
    }
    return dec;
}