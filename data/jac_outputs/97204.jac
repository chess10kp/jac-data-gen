"""Returns an integer representing a number of microseconds."""
def microseconds(h: int, m: int, s: int, f: int) -> int {
    return (int(h) * 3600 + int(m) * 60 + int(s)) * 1000000 + int(f) * 1000;
}