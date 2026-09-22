"""Returns True if some value in the list is a prefix for another value in this list."""
def has_prefix(x: list[str]) -> bool {
    for val in x {
        if len(list(filter(val.startswith, x))) > 1 {
            return True;
        }
    }
    return False;
}