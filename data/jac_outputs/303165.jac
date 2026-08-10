"""Defaultdict(list) behaviour for keys record."""
def append_keys(
    results: dict[str, dict[str, list[str]]],
    search_key: str,
    keys: list[str]
) -> dict[str, dict[str, list[str]]] {
    if search_key in results {
        results[search_key]["keys"].extend(keys);
    } else {
        results[search_key] = {"keys": keys};
    }
    return results;
}