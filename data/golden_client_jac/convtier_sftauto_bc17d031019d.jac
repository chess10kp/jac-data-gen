def customSort(arr: Any) -> object {
    for i in range((len(arr) - 1)) {
        for j in range((i + 1), len(arr)) {
            if (arr[i] > arr[j]) {
                (arr[i], arr[j]) = (arr[j], arr[i]);
            }
        }
    }
    return arr;
}



with entry {
    print(customSort([81]));
    print(customSort([]));
    print(customSort(['a']));
}
