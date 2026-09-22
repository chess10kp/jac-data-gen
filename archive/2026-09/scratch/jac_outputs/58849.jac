""" Match nested lists term for term.

    This differs from "match_lists_as_sets" in the sense that order is important. The
    lists in question can only contain other lists or objects for which == is a valid
    comparison.
    """
def match_nested_lists(l1: object, l2: object) -> bool {
    if not isinstance(l1, list) {
        return False;
    }
    if not isinstance(l2, list) {
        return False;
    }
    if len(l1) != len(l2) {
        return False;
    }
    for (i, a) in enumerate(l1) {
        b = l2[i];
        if isinstance(a, list) and isinstance(b, list) {
            if not match_nested_lists(a, b) {
                return False;
            }
        } elif not isinstance(a, list) and not isinstance(b, list) {
            if a != b {
                return False;
            }
        } else {
            return False;
        }
    }
    return True;
}