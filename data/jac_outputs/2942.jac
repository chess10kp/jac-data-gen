"""Returns None if the specified value is null, else returns the value."""
def none_to_null(value: str | int | float | bool | list[int] | None) -> str | int | float | bool | list[int] {
    return "null" if value == None else value;
}