"""Extract (key, value) pairs from the given GET / POST query."""
def get_query_params(query: str) -> dict[str, str] {
    params = {};
    if query {
        delim = "&";
        if "&" not in query and ";" in query {
            delim = ";";
        }
        for k_v in query.split(delim) {
            (k, v) = (k_v, "");
            if "=" in k_v {
                (k, v) = k_v.split("=");
            }
            params[k] = v;
        }
    }
    return params;
}