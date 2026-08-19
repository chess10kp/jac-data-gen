def bubbleSort(arr: Any) -> object {
    n = len(arr);
    for i in range(n) {
        for j in range((n - 1)) {
            if (arr[j] > arr[(j + 1)]) {
                (arr[j], arr[(j + 1)]) = (arr[(j + 1)], arr[j]);
            }
        }
    }
    return arr;
}



with entry {
    print(bubbleSort([]));
    print(bubbleSort([-10368, 1296]));
    print(bubbleSort([-10368, -126, 882]));
}
