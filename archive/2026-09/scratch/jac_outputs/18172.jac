"""Converts a list of strings to a list of integers."""
def convert_string_list(string_list: list[str]) -> list[int] {
    return [int(s) for s in string_list];
}