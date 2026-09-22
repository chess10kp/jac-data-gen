"""Format time for nice printing."""
def format_time(t: float) -> str {
    if t > 60 or t == 0 {
        units = 'min';
        t /= 60;
    } elif t > 1 {
        units = 's';
    } elif t > 0.001 {
        units = 'ms';
        t *= 1000.0;
    } elif t > 1e-06 {
        units = 'us';
        t *= 1000000.0;
    } else {
        units = 'ns';
        t *= 1000000000.0;
    }
    return '%.1f %s' % (t, units);
}