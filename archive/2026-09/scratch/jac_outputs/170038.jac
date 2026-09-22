"""Adds query and candidate datasets to json object."""
def add_data_to_json(
    json_obj: dict[str, list[dict[str, str]]],
    query_data: list[dict[str, str]],
    candidate_data: list[dict[str, str]]
) -> dict[str, list[dict[str, str]]] {
    json_obj['query_data'] = query_data;
    json_obj['candidate_data'] = candidate_data;
    return json_obj;
}