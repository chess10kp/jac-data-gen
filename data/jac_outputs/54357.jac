"""Parse indices from comma-separated and ranged index string."""
def parse_indices(in_: str) -> list[int] {
    comps = in_.split(',');
    indices = set();
    for comp in comps {
        if '-' in comp {
            (low, high) = comp.split('-');
            indices.update(range(int(low), int(high) + 1));
        } else {
            indices.add(int(comp));
        }
    }
    return sorted(indices);
}