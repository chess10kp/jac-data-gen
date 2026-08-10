"""
Convert Elasticsearch results into RPC results conforming to the spec for
the "search_types" method.
"""
def search_types(params: dict[str, str], results: dict[str, str | int | float | dict[str, dict[str, dict[str, list[dict[str, str | int]]]]]], meta: dict[str, str]) -> dict[str, dict[str, int] | int] {
    search_time = results['search_time'];
    buckets = results['aggregations']['type_count']['counts'];
    counts_dict: dict[str, int] = {};
    for count_obj in buckets {
        counts_dict[count_obj['key']] = counts_dict.get(count_obj['key'], 0);
        counts_dict[count_obj['key']] += int(count_obj['count']);
    }
    return {'type_to_count': counts_dict, 'search_time': int(search_time)};
}