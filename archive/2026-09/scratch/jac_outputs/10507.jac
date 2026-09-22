"""Merge list values from d2 into d, optionally in place."""
def list_merge_values(d: dict[int, list[int]], d2: dict[int, list[int]], in_place: bool = True) -> dict[int, list[int]] {
    d3 = d.copy() if not in_place else d;
    for (key, val) in d2.items() {
        if key not in d3 {
            d3[key] = val;
        } else {
            d3[key].extend(val);
        }
    }
    return d3;
}