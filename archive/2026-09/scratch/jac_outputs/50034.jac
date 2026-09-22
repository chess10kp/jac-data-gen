"""Compares two groups of objects, returning the sets: onlyIn1, inBoth, onlyIn2."""
def setCompare(iter1: list[int], iter2: list[int]) -> tuple[set[int], set[int], set[int]] {
    s1 = set(iter1);
    s2 = set(iter2);
    intersect = s1 & s2;
    return (s1 - intersect, intersect, s2 - intersect);
}