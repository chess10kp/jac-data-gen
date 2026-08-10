"""Bubble sort a collection in place."""
def bubble_sort(collection: list[int]) -> list[int] {
    panjang = len(collection);
    for i in range(panjang - 1) {
        swap = False;
        for j in range(panjang - 1 - i) {
            if collection[j] > collection[j + 1] {
                swap = True;
                (collection[j], collection[j + 1]) = (collection[j + 1], collection[j]);
            }
        }
        if not swap {
            break;
        }
    }
    return collection;
}