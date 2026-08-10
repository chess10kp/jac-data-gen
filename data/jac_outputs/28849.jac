"""Generate a list of counts for each item in the input list. Outputs with highest counted item at index 0."""
def count(items: list) -> list {
    def row2(k: list) -> int {
        return k[1];
    }
    if isinstance(items[0], list) {
        items = [tuple(x) for x in items];
    }
    uniqs = [[x, items.count(x)] for x in set(items)];
    uniqs.sort(key=row2, reverse=True);
    return uniqs;
}