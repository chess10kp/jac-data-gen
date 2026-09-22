"""Given a dictionary with values that are Collections, return their union."""
def union_values(dictionary: dict[str, list[int]]) -> list[int] | set[int] {
    sets = [set(p) for p in dictionary.values()];
    return sorted(set.union(*sets)) if sets else set();
}