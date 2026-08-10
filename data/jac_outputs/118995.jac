"""Returns whether the given value is the Python equivalent of an std_logic."""
def is_std_logic(value: bool | int | float | str | None) -> bool {
    return value is True or value is False;
}