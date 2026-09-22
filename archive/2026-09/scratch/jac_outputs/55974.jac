"""Parse `filters` CLI argument as key=value pairs."""
def parse_filters(filters: list[str] = []) -> dict[str, str] {
    ret = {};
    for f in filters {
        (k, v) = f.split("=");
        ret[k] = v;
    }
    return ret;
}