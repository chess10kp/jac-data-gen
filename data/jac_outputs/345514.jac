"""Return a dictionary with each key mapping to a set of values."""
def create_rdict(d: dict[str, int]) -> dict[int, set[str]] {
    rd: dict[int, set[str]] = {};
    for (key, value) in d.items() {
        v = rd.setdefault(value, set());
        v.add(key);
    }
    return rd;
}