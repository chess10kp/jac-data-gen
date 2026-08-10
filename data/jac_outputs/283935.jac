"""
    Determines whether list a is part of list b, either forwards or backwards
    """
def list_in_list(a: list[object], b: list[object]) -> bool {
    if any(a == b[offset:offset + len(a)] for offset in range(len(b) - len(a) + 1)) {
        return True;
    }
    a.reverse();
    if any(a == b[offset:offset + len(a)] for offset in range(len(b) - len(a) + 1)) {
        return True;
    }
    return False;
}