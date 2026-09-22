"""Check if item provides a nested dictionary."""
def is_nested_dict(item: dict[str, object]) -> bool {
    item = next(iter(item.values()));
    return isinstance(item, dict);
}