"""Convert an association list to a dictionary."""
def _assoc_list_to_map(lst: list[tuple[str, float]]) -> dict[str, list[float]] {
    d = {};
    for (run_id, metric) in lst {
        d[run_id] = (d[run_id] + [metric]) if run_id in d else [metric];
    }
    return d;
}