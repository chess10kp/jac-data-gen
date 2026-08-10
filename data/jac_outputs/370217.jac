"""
    Try to convert item to lowercase, if it is string.
    """
def _lower_if_str(item: str | int | float | bool | list[object] | dict[str, object]) -> str | int | float | bool | list[object] | dict[str, object] {
    if isinstance(item, str) {
        return item.lower();
    }
    return item;
}