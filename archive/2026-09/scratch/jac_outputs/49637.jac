"""Return whether items are in sorted non-decreasing order."""
def is_sorted[T](items: list[T]) -> bool {
    for i in range(len(items) - 1) {
        if items[i] > items[i + 1] {
            return False;
        }
    }
    return True;
}