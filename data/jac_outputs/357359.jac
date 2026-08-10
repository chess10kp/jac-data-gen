"""Sort list by using BubbleSort algorithm."""
def bubble_sort(lst: list[int]) -> list[int] {
    for i in range(len(lst)) {
        for j in range(0, len(lst) - i - 1) {
            if lst[j] > lst[j + 1] {
                (lst[j], lst[j + 1]) = (lst[j + 1], lst[j]);
            }
        }
    }
    return lst;
}