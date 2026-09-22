"""Utility function."""
def convert_1d_list_to_string(data: list[int | float | str | bool]) -> str {
    return ",".join([str(d) for d in data]);
}