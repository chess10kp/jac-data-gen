"""Check if every element in a list is unique."""
def list_is_unique(ls: list) -> bool {
    return len(ls) == len(set(ls));
}