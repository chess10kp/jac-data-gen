"""Convert a time specification on the form hh:mm to minutes."""
def to_minutes(s: str) -> int {
    (h, m) = s.split(':');
    return int(h) * 60 + int(m);
}