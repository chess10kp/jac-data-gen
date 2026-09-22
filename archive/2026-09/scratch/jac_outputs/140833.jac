"""Return the elapsed time between t0 and t1 in h:m:s formatted string"""
def printtime(t0: float, t1: float) -> str {
    elapsed = t1 - t0;
    s = elapsed % 60;
    total_min = elapsed // 60;
    h = total_min // 60;
    m = total_min % 60;
    fmt = '%d:%02d:%02d' % (h, m, s);
    return fmt;
}