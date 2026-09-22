"""Parse a I[.F] seconds value into (seconds, microseconds)."""
def _parsems(value: str) -> tuple[int, int] {
    if "." not in value {
        return (int(value), 0);
    }
    (i, f) = value.split(".");
    return (int(i), int(f.ljust(6, "0")[:6]));
}