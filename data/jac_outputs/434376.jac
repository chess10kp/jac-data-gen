"""Fill gaps of arrays with size with indicies and elems."""
def fill_gaps[T](indicies: list[int], elementss: list[T], size: int, gap: Callable[[], T]) -> list[T] {
    full: list[T | None] = [None] * size;
    for (ind, elem) in zip(indicies, elementss) {
        full[ind] = elem;
    }
    for ind in range(size) {
        if full[ind] is None {
            full[ind] = gap();
        }
    }
    return full;
}