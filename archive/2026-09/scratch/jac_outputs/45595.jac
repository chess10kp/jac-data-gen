"""Determines the base key in the dict for required items."""
def get_req_key(req_items: list[dict[str, object]] = [{}]) -> str {
    return [
        key
        for key in req_items[0].keys()
        if key not in ("description", "dict_params", "default_values")
    ][0];
}