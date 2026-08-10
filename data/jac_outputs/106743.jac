"""Given (key, value) pairs, return a table mapping each key to a list of all its values."""
def group(pairs: list[tuple[int | str, int | float | str]]) -> dict[int | str, list[int | float | str]] {
    table = {};
    for (k, v) in pairs {
        table.setdefault(k, []).append(v);
    }
    return table;
}