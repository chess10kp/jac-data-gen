"""Helper function for assign_colors_to_clusters()."""
def invert_dict(old_dict: dict[str, int]) -> dict[int, list[str]] {
    inv_dict = {};
    for (k, v) in old_dict.items() {
        inv_dict[v] = inv_dict.get(v, []);
        inv_dict[v].append(k);
    }
    return inv_dict;
}