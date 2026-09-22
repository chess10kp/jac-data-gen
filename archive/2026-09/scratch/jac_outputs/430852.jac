"""Return the ascent set of a standard tableau (encoded as a sorted list)."""
def ascent_set(t: list[list[int]]) -> list[int] {
    row_locations: dict[int, int] = {};
    for (i, row) in enumerate(t) {
        for entry in row {
            row_locations[entry] = i;
        }
    }
    n = len(row_locations);
    if not n {
        return [];
    }
    ascents = [n];
    for i in range(1, n) {
        x = row_locations[i];
        u = row_locations[i + 1];
        if u <= x {
            ascents.append(i);
        }
    }
    return sorted(ascents);
}