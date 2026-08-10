"""Merge two total-time dictionaries by adding collected time per hierarchical element."""
def merge_total_time_dict(a: dict[str, tuple[float, dict]], b: dict[str, tuple[float, dict]]) -> dict[str, tuple[float, dict]] {
    all_keys = set(a).union(set(b));
    total = dict();
    for key in all_keys {
        (t_a, d_a) = a.get(key, (0, dict()));
        (t_b, d_b) = b.get(key, (0, dict()));
        total[key] = (t_a + t_b, merge_total_time_dict(d_a, d_b));
    }
    return total;
}