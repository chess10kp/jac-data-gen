"""
    Generate response object
    """
def generate_resp_obj(
    content_type: str,
    responses: dict[str, dict[str, dict | str | bool]]
) -> dict[str, str | bool | dict[str, dict | str | bool]] {
    resp_obj = {"type": "object", "properties": dict(), "additionalProperties": False};
    for (resp_key, resp_val) in responses.items() {
        if (
            'content' in responses[resp_key]
            and 'schema' in resp_val['content'][content_type]
        ) {
            resp_obj['properties'][resp_key] = resp_val['content'][content_type]['schema'];
        } else {
            resp_obj['properties'][resp_key] = resp_val;
        }
    }
    return resp_obj;
}