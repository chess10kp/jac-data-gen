"""Convert dec in decimal degrees to sexigesimal."""
def dec_to_sex(dec: float, delimiter: str = ':') -> str {
    if dec >= 0 {
        hemisphere = '+';
    } else {
        hemisphere = '-';
        dec *= -1;
    }
    dec_deg = int(dec);
    dec_mm = int((dec - dec_deg) * 60);
    dec_ss = int(((dec - dec_deg) * 60 - dec_mm) * 60);
    dec_f = int(((((dec - dec_deg) * 60 - dec_mm) * 60) - dec_ss) * 10);
    return (
        hemisphere
        + '%02d' % dec_deg
        + delimiter
        + '%02d' % dec_mm
        + delimiter
        + '%02d' % dec_ss
        + '.'
        + '%01d' % dec_f
    );
}