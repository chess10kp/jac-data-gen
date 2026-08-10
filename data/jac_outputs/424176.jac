"""Returns true if v1 and v2 are both bools and not equal"""
def compliment_bools(v1: bool | int | str | float, v2: bool | int | str | float) -> bool {
    return isinstance(v1, bool) and isinstance(v2, bool) and v1 != v2;
}