"""
    encode given `value` as sexagesimal string

    :param float value:  declination in decimal degrees
    :return str: sring in sexagesmial form

    """
def deg2dec(value: Any) -> object {
    value = round(value, 5);
    sign = 1;
    if (value < 0) {
        sign = -1;
        value = abs(value);
    }
    (dd, r1) = divmod(value, 1);
    (mm, r2) = divmod((r1 * 60), 1);
    ss = r2 * 60;
    return "{0:+03d}:{1:02d}:{2:05.2f}".format(int((sign * dd)), int(mm), ss);
}