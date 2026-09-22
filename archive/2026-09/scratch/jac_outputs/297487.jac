import re;

"""
It contains a pair of any two letters that appears at least twice in the string without overlapping,
like xyxy (xy) or aabcdefgaa (aa), but not like aaa (aa, but it overlaps).
"""
def contains_repeated_pairs(string: str) -> bool {
    return bool(re.search(r"(..).*\1", string));
}