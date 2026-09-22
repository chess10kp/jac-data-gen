"""Custom printing of elapsed time."""
def pretty_string_time(t: float) -> str {
    if t > 4000 {
        return 't=%.1fh' % (t / 3600);
    } elif t > 300 {
        return 't=%.0fm' % (t / 60);
    }
    return 't=%.0fs' % t;
}