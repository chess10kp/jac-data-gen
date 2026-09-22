"""
    Split data from ``iterable`` into two lists.
    Each element is passed to function ``pred``; elements
    for which ``pred`` returns True are put into ``yes`` list,
    other elements are put into ``no`` list.
    """
def split_data[T](iterable: Iterable[T], pred: Callable[[T], bool]) -> tuple[list[T], list[T]] {
    yes: list[T] = [];
    no: list[T] = [];
    for d in iterable {
        if pred(d) {
            yes.append(d);
        } else {
            no.append(d);
        }
    }
    return (yes, no);
}