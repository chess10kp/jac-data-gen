"""Filter out the dicts with values for key."""
def filter_list_dicts(list_dicts: list[dict[str, str]], key: str, values: list[str]) -> list[dict[str, str]] {
    return [e for e in list_dicts if e[key] in values];
}