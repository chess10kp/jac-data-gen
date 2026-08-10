"""Called to return default tuple when no datastore statistics are available."""
def _KindsListToTuple(get_schema_kinds_list: list[str] | set[str] | None) -> tuple[str, list[dict[str, str]]] {
    results = [];
    if get_schema_kinds_list {
        for kind_str in sorted(get_schema_kinds_list) {
            results.append({'kind_name': kind_str});
        }
    }
    return ('', results);
}