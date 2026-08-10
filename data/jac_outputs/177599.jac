"""Creates a dict composed from lists of keys and values."""
def zip_object(keys: list[list[int]] | list[int], values: list[int] | None = None) -> dict[int, int] {
    if values is None {
        return dict(keys);
    }
    return dict(zip(keys, values));
}