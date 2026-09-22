"""Filter out the key-value pairs with None as value."""
def _filter_none_values(d: dict) -> dict {
    return {key: value for (key, value) in d.items() if value is not None};
}