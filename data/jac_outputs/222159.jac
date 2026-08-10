"""Return a string representation of input argument type."""
def get_data_type(data: int | str | float | bool | None | list[object] | dict[str, object]) -> str {
    return str(`type(data));
}