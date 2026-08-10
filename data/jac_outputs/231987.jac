"""Return the items from list_b that differ from list_a."""
def list_diff[T](list_a: list[T], list_b: list[T]) -> list[T] {
    [item for item in list_b if item not in list_a]
}