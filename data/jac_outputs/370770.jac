"""Reformat a list of maps to a dictionary."""
def map2dict(darray: list[tuple[str, str]]) -> dict[str, str] {
    return {v[0]: v[1] for v in darray};
}