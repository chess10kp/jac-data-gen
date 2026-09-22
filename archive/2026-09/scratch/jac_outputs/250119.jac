"""Set Value Divider
    Args:
        'state': value
    Returns:
        A list ``[value, value]``. No copying is performed.
    """
def divide_set_value(state: int, config: dict[str, str | int | float]) -> list[str | int | float] {
    value = config["value"];
    return [value, value];
}