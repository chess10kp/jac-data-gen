"""Return first member of an iterator."""
def first[T](iterator: Iterator[T], `default: T | None = None) -> T | None {
    return next(iterator, `default);
}