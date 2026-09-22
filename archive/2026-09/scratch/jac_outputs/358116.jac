"""
    Loops over a list and replaces any values that are None, False or blank
    with arg.
    """
def item_default(list_values: list[str | int | float | None | bool], arg: str) -> list[str | int | float] {
    if list_values {
        return [item for item in list_values if item];
    }
    return [];
}