"""Check that all values in given list are equal."""
def all_equal(values: list[str | int | float | bool]) -> bool {
    return all(values[0] == v for v in values);
}