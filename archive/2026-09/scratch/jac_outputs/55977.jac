"""Return True if two list have at least an element in common, False otherwise."""
def commonMember(a: list[int], b: list[int]) -> bool {
    return bool(set(a) & set(b));
}