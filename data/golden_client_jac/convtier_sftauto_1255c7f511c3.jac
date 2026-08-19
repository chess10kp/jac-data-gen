def modified_bubble_sort(lst: Any) -> object {
    n = len(lst);
    for i in range(0, n, 2) {
        for j in range(0, (n - i - 2), 2) {
            if (lst[j] > lst[(j + 2)]) {
                (lst[j], lst[(j + 2)]) = (lst[(j + 2)], lst[j]);
            }
        }
    }
    return lst;
}



with entry {
    print(modified_bubble_sort('hello'));
    print(modified_bubble_sort('Racecar'));
    print(modified_bubble_sort([]));
}
