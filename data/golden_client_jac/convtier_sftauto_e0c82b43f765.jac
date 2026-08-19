def bubble_sort_descending(arr: Any) -> object {
    n = len(arr);
    swapped = True;
    while swapped {
        swapped = False;
        for i in range((n - 1)) {
            if (arr[i] < arr[(i + 1)]) {
                (arr[i], arr[(i + 1)]) = (arr[(i + 1)], arr[i]);
                swapped = True;
            }
        }
        n -= 1;
    }
    return arr;
}



with entry {
    print(bubble_sort_descending([9, 2]));
    print(bubble_sort_descending([2]));
    print(bubble_sort_descending([34]));
}
