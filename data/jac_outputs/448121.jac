"""Flattens a list of lists to the first level.

Given a list containing a mix of scalars and lists,
flattens down to a list of the scalars within the original
list.
"""
def flatten(l: list | int | float | str | bool) -> list[int | float | str | bool] {
    if not isinstance(l, list) {
        return [l];
    }
    return sum(map(flatten, l), []);
}