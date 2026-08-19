def non_increasing_sort(arr: Any) -> object {
    n = len(arr);
    for i in range(n) {
        for j in range((i + 1), n) {
            if (arr[i] < arr[j]) {
                (arr[i], arr[j]) = (arr[j], arr[i]);
            }
        }
    }
    return arr;
}



with entry {
    print(non_increasing_sort([]));
}
