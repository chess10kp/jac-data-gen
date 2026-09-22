"""
Replace all spaces with underscores for strings in the list.

Requires that the list contains strings for each element.

lst: list of strings
"""
def replace_spaces(lst: list[str]) -> list[str] {
    return [s.replace(" ", "_") for s in lst];
}