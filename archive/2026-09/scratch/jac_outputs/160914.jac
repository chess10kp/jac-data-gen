"""Index of all list members that include keyword."""
def index_keyword(lst: list[str], keyword: str) -> list[int] {
    return [i for (i, x) in enumerate(lst) if keyword in x];
}