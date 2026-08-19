def bubble_sort(lst: Any) -> object {
    n = len(lst);
    for i in range((n - 1)) {
        for j in range((n - i - 1)) {
            if (lst[j] > lst[(j + 1)]) {
                (lst[j], lst[(j + 1)]) = (lst[(j + 1)], lst[j]);
            }
        }
    }
    return lst;
}



with entry {
    print(bubble_sort([]));
}
