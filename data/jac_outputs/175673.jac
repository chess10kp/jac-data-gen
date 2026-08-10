"""The inverse of add_prefix.

Returns all prefixed elements of a dict with the prefices stripped.
"""
def get_prefixed(field_dict: dict[str, object], prefix: str) -> dict[str, object] {
    prefix_len = len(prefix) + 1;
    return {
        k[prefix_len:]: v
        for (k, v) in field_dict.items()
        if k.startswith(prefix)
    };
}