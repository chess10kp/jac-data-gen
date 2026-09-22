"""Turn a duration in seconds into a human readable string."""
def duration(s: int) -> str {
    m = s // 60;
    s = s % 60;
    h = m // 60;
    m = m % 60;
    d = h // 24;
    h = h % 24;
    parts = [];
    if d {
        parts.append('%dd' % d);
    }
    if h {
        parts.append('%dh' % h);
    }
    if m {
        parts.append('%dm' % m);
    }
    if s {
        parts.append('%ds' % s);
    }
    return ' '.join(parts);
}