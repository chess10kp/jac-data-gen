"""Return index of first item matching predicate."""
def _index_matching_predicate(seq: list[int], pred: Callable[[int], bool]) -> int | None {
    for (i, v) in enumerate(seq) {
        if pred(v) {
            return i;
        }
    }
    return None;
}