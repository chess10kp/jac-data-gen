"""Convert a nested list with arbitrary structure to a nested tuple instead."""
def _deep_tuple(item: list | dict | tuple | str | int | float | bool | bytes | None) -> tuple | dict | str | int | float | bool | bytes | None {
    if isinstance(item, list) {
        return tuple(_deep_tuple(i) for i in item);
    }
    return item;
}