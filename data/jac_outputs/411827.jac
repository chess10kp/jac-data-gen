"""Multiplies a list of variables together."""
def multAll(lst: list[float]) -> float {
    if len(lst) == 0 {
        return 0;
    }
    out = lst[0];
    for item in lst[1:] {
        out *= item;
    }
    return out;
}