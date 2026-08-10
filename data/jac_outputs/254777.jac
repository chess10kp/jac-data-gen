"""Get variables in a triple pattern"""
def get_vars(triple: dict[str, str]) -> set[str] {
    return {v for (_, v) in triple.items() if v.startswith('?')};
}