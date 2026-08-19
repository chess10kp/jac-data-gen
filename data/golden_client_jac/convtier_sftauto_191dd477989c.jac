def bubble_sort(arr: Any) -> object {
    n = len(arr);
    if (n <= 1) {
        return arr;
    }
    swapped = True;
    while swapped {
        swapped = False;
        for i in range(1, n) {
            if (arr[(i - 1)] > arr[i]) {
                (arr[(i - 1)], arr[i]) = (arr[i], arr[(i - 1)]);
                swapped = True;
            }
        }
    }
    return arr;
}



with entry {
    print(bubble_sort([]));
}
