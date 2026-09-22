"""Create frequent candidate 1-itemset C1 by scanning data set."""
def create_C1(data_set: list[list[object]]) -> set[frozenset[object]] {
    C1 = set();
    for t in data_set {
        for item in t {
            item_set = frozenset([item]);
            C1.add(item_set);
        }
    }
    return C1;
}