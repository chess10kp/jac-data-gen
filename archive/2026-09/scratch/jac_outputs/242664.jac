"""If single value, try to parse as integer, else try to parse as list of integer."""
def coerce_list_of_ints(val: int | float | str | list[int | float | str]) -> list[int] {
    if isinstance(val, list) {
        return [int(x) for x in val];
    }
    return [int(val)];
}