"""Returns TRUE iff one element in <phrase> is TRUE"""
def or_sum(phrase: list[set[bool]]) -> set[bool] {
    total = set[bool]();
    for x in phrase {
        total = total.union(x);
    }
    return total;
}