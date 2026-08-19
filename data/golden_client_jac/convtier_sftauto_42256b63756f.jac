def bubble_sort(arr: Any) -> object {
    n = len(arr);
    swapped = True;
    while swapped {
        swapped = False;
        for i in range((n - 1)) {
            if (arr[i] > arr[(i + 1)]) {
                (arr[i], arr[(i + 1)]) = (arr[(i + 1)], arr[i]);
                swapped = True;
            }
        }
    }
    return arr;
}



with entry {
    print(bubble_sort([]));
}
