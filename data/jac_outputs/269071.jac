"""Parse time duration string into seconds as a float-like string."""
def duration_parser(delta: str) -> str {
    (t, f) = delta.split(".");
    (h, m, s) = t.split(":");
    return f"{int(h) * 60 * 60 + int(m) * 60 + int(s)}.{f}";
}