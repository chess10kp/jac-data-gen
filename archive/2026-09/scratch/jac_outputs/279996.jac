"""Pads the items list up to the expected length with the provided defaults."""
def defaults(items: list[str], expected: int, *default_values: str) -> list[str] {
    if len(items) == expected {
        return items;
    }
    if len(items) + len(default_values) < expected {
        raise Exception("Too few items, even with defaults.");
    }
    items = list(items);
    items.extend(default_values[len(items) - expected - 1:]);
    return items;
}