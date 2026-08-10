"""take a string of the form "YYYY-MM-DD" (or "YYYY"), terurn a tuple (year, month, date) of three integers"""
def to_ymd(s: Any) -> object {
    if not s {
        return;
    }
    s = s + '--';
    y = s.split('-')[0];
    m = s.split('-')[1];
    d = s.split('-')[2];
    if y {
        y = int(y);
    } else {
        y = None;
    }
    if m {
        m = int(m);
    } else {
        m = None;
    }
    if d {
        d = int(d);
    } else {
        d = None;
    }
    return (y, m, d);
}