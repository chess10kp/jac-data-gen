"""Finds all key, value in class_mapping s.t key is a substring of term."""
def find_str_in_dict(term: str, class_mapping: dict[str, int]) -> list[tuple[int, str]] {
    return [(v, k) for (k, v) in class_mapping.items() if k in term.lower()];
}