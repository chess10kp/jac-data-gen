"""Return the first element in seq matching predicate, or None."""
def find[T](predicate: Callable[[T], bool], seq: list[T]) -> T | None {
    for element in seq {
        if predicate(element) {
            return element;
        }
    }
    return None;
}