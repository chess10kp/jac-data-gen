"""Finds the set (i.e. no duplicates) of all elements in the first list not
contained in the second list. Objects and Arrays are compared in terms of
value equality, not reference equality"""
def difference(xs: list, ys: list) -> list {
    out = [];
    for x in xs {
        if x not in ys and x not in out {
            out.append(x);
        }
    }
    return out;
}