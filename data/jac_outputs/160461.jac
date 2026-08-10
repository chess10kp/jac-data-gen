"""
Return True, if no more than min_set_diff members of set2
are contained in set1.
i.e, set2 is almost a subset of set1. See example for clarity:

Example
-------
>>>  is_almost_subset(set(["A","B","C","D"]), set(["A", "K"]), 2)
True
>>> is_almost_subset(set(["A","B","C","D"]), set(["A", "K"]), 1)
False
"""
def is_almost_subset(set1: set[object], set2: set[object], min_set_diff: int = 2) -> bool {
    len(set(set2) - set(set1)) < min_set_diff
}