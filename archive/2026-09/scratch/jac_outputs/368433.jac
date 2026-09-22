"""
    Implementation of bubble sort.
    O(n2) and thus highly ineffective.
    """
def bubble_sort[T](seq: list[T]) -> list[T] {
    size = len(seq) - 1;
    for num in range(size, 0, -1) {
        for i in range(num) {
            if seq[i] > seq[i + 1] {
                temp = seq[i];
                seq[i] = seq[i + 1];
                seq[i + 1] = temp;
            }
        }
    }
    return seq;
}