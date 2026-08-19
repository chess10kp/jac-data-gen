def bubbleSort(arr: Any) -> object {
    n = len(arr);
    for i in range(n) {
        swapped = False;
        for j in range(0, (n - i - 1)) {
            if (arr[j] > arr[(j + 1)]) {
                (arr[j], arr[(j + 1)]) = (arr[(j + 1)], arr[j]);
                swapped = True;
            }
        }
        if not swapped {
            break;
        }
    }
    return arr;
}



with entry {
    print(bubbleSort([81]));
    print(bubbleSort([]));
    print(bubbleSort(['a']));
}
