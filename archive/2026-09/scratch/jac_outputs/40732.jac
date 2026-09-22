"""Returns [[trues], [falses]], where [trues] is the items in
    'iterable' that satisfy 'pred' and [falses] is all the rest."""
def partition[T](pred: Callable[[T], bool], iterable: list[T]) -> tuple[list[T], list[T]] {
    trues = [];
    falses = [];
    for item in iterable {
        if pred(item) {
            trues.append(item);
        } else {
            falses.append(item);
        }
    }
    return (trues, falses);
}