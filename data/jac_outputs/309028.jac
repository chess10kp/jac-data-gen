"""Validate that a given square is valid.."""
def validate(s: Any) -> object {
    if (`type(s) == int) {
        return ((s == 0) or (s == 1));
    }
    if ((`type(s) != `list) or (len(s) != 4)) {
        return False;
    }
    for q in s {
        if not validate(q) {
            return False;
        }
    }
    return True;
}