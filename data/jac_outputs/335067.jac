"""Determines whether two lists are equal."""
def check_equal(list: list[object]) -> bool {
    return list[1:] == list[:-1];
}