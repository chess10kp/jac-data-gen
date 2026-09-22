"""Intersection of two dicts.
Return data in the first dict for the keys existing in both dicts."""
def intersection(d1: dict[str, object], d2: dict[str, object]) -> dict[str, object] {
    ret: dict[str, object] = {};
    for k in d1 {
        if k in d2 {
            ret[k] = d1[k];
        }
    }
    return ret;
}