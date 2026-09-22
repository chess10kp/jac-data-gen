"""Create a new dictionary with a subset of the attributes."""
def project(atts: list[str], row: dict[str, str], renaming: dict[str, str] = {}) -> dict[str, str] {
    res = {};
    for c in atts {
        res[c] = row[renaming[c]] if c in renaming else row[c];
    }
    return res;
}