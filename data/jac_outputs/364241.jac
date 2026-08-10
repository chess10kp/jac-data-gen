"""Return the inverse keyword that undoes a reordering permutation."""
def invert_keyword(keyword: list[int]) -> list[int] {
    return [keyword.index(index) for index in range(len(keyword))];
}