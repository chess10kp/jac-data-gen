"""extract key-value pairs from a url query string

    for example
    "collection=23&someoption&format=json"
      -> {"collection": "23", "someoption": None, "format": "json"}

    """
def _parse_query(query: str) -> dict[str, str | None] {
    result = {};
    for part in query.split("&") {
        p = part.split("=");
        if len(p) == 2 {
            result[p[0]] = p[1];
        } elif len(p) == 1 {
            result[p[0]] = None;
        }
    }
    return result;
}