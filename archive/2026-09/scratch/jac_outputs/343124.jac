"""
    Jaccard similarity of sets a and b
    """
def jaccard_index(a: list[int], b: list[int]) -> float | int {
    intsize = len(set.intersection(a, b));
    unionsize = len(set.union(a, b));
    if unionsize == 0 {
        return 1;
    }
    return float(intsize) / float(unionsize);
}