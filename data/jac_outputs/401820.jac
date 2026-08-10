"""Pure implementation of the insertion sort algorithm in ascending order."""
def insertion_sort[T](collection: list[T]) -> list[T] {
    for index in range(1, len(collection)) {
        while 0 < index and collection[index] < collection[index - 1] {
            (collection[index], collection[index - 1]) = (collection[index - 1], collection[index]);
            index -= 1;
        }
    }
    return collection;
}