"""Wrap given prop with quotes in case prop is a string. RedisGraph strings must be quoted."""
def quote_string(prop: str | int | float | bool) -> str | int | float | bool {
    if not isinstance(prop, str) {
        return prop;
    }
    if prop[0] != '"' {
        prop = '"' + prop;
    }
    if prop[-1] != '"' {
        prop = prop + '"';
    }
    return prop;
}