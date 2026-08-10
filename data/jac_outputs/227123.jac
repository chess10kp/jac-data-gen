"""Construct a regex representing "any of" the given possibilities."""
def any_of(possibilities: list[str], to_add: str = "") -> str {
    assert len(possibilities) > 0;
    s = "(?:";
    if len(to_add) > 0 {
        s += possibilities[0] + to_add + " ";
    } else {
        s += possibilities[0];
    }
    for i in range(len(possibilities) - 1) {
        if len(to_add) > 0 {
            s += "|" + possibilities[i + 1] + to_add + " ";
        } else {
            s += "|" + possibilities[i + 1];
        }
    }
    return s + ")";
}