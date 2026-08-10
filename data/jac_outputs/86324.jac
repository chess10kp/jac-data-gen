"""Check if a list only contains either empty elements or whitespace."""
def is_empty_list(l: list[str]) -> bool {
    return all(s == '' or s.isspace() for s in l);
}