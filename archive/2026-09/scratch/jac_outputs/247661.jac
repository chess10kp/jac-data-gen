"""Given a dictionary `d`, produce a dictionary that inverts its key-value relationship.

Warning:
    If a value appears multiple times in `d` the resulting inverse dictionary will contain
    only the last key that was encountered while iterating over `d` (which is, by definition,
    undefined ;-).
"""
def invert(d: dict[str, int]) -> dict[int, str] {
    return {v: k for (k, v) in d.items()};
}