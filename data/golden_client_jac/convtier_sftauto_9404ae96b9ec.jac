def bubble_sort_by_abs(lst: Any) -> object {
    n = len(lst);
    for i in range((n - 1)) {
        for j in range(0, (n - i - 1)) {
            if (`abs(lst[j]) > `abs(lst[(j + 1)])) {
                (lst[j], lst[(j + 1)]) = (lst[(j + 1)], lst[j]);
            }
        }
    }
    return lst;
}



with entry {
    print(bubble_sort_by_abs([]));
}
