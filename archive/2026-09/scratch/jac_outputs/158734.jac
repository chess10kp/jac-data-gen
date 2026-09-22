"""Returns min value even if one of the value is None."""
def smart_min(v1: int | float | str | None, v2: int | float | str | None) -> int | float | str | None {
    if v1 is None {
        return v2;
    }
    if v2 is None {
        return v1;
    }
    return min(v1, v2);
}