"""Remove entries in the dict object where the value is None."""
def filter_empty_values(mapping_object: dict[str, object]) -> dict[str, object] {
    return {key: val for (key, val) in mapping_object.items() if val is not None};
}