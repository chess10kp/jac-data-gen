"""Copies thelist, modifies values to range 0 to 100.

Designed to handle integer values. Will convert floats.
"""
def adjustList(theList: list[int | float]) -> list[int | float] {
    return [100 if x > 100 else 0 if x < 0 else x for x in theList];
}