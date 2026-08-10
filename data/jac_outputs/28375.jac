"""Determine if dicts a and b have the same keys."""
def same_keys(a: dict[object, object], b: dict[object, object]) -> bool {
    for ak in a {
        if ak not in b {
            return False;
        }
    }
    for bk in b {
        if bk not in a {
            return False;
        }
    }
    return True;
}