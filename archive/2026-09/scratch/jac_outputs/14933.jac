"""
    Splits *seq*, placing alternating values into the returned iterables
    """
def alternate[T](seq: list[T]) -> tuple[list[T], list[T]] {
    return (seq[::2], seq[1::2]);
}