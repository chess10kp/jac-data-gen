"""Extracts preprocessor defines from a list of -D strings."""
def _extract_defines_from_option_list(lst: list[str]) -> list[str] {
    return [item[2:] for item in lst if item.startswith("-D")];
}