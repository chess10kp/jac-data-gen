"""
Removes duplicates from a list. Elements are ordered by the original
order of their first occurrences.
"""
def uniq(a: list[int]) -> list[int] {
    if len(a) == 0 {
        return [];
    }
    return [a[0]] + uniq([x for x in a if x != a[0]]);
}