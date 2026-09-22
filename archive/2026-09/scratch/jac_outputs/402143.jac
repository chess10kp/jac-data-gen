"""Check that every element in to_check is contained in original."""
def check_issubset(to_check: list[str], original: list[str] | set[str]) -> bool {
    s = set();
    for item in to_check {
        s.add(item);
    }
    return s.issubset(original);
}