"""Create context for a single hit in the search.

    Args:
        hit(Dict): a dictionary representing a single hit in the search.

    Returns:
        (dict).The hit context.
        (list).the headers of the hit.
    """
def get_hit_table(hit: dict[str, str | int | float | dict[str, str | int | float] | None]) -> tuple[dict[str, str | int | float | dict[str, str | int | float] | None], list[str]] {
    table_context = {
        '_index': hit.get('_index'),
        '_id': hit.get('_id'),
        '_type': hit.get('_type'),
        '_score': hit.get('_score')
    };
    headers = ['_index', '_id', '_type', '_score'];
    source = hit.get('_source');
    if source is not None {
        for source_field in (source as dict[str, str | int | float]).keys() {
            table_context[str(source_field)] = (source as dict[str, str | int | float]).get(str(source_field));
            headers.append(source_field);
        }
    }
    return (table_context, headers);
}