"""if item is not None and Not a list returns [item] else returns item"""
def listify(item: list[int] | tuple[int, ...] | int | str | float | bool | None) -> list[int | str | float | bool] | list[int] | tuple[int, ...] | int | str | float | bool | None {
    if item is not None and not isinstance(item, (list, tuple)) {
        return [item];
    }
    return item;
}