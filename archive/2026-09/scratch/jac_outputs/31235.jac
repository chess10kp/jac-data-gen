"""Given an iterable, returns a list of its contents converted to floats."""
def to_float_list(a: list[int | float | str]) -> list[float] {
    return [float(i) for i in a];
}