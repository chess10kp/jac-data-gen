def custom_sort(arr: Any) -> object {
    for i in range(len(arr)) {
        for j in range((i + 1), len(arr)) {
            if (arr[j] > arr[i]) {
                (arr[i], arr[j]) = (arr[j], arr[i]);
            }
        }
    }
    unique_elements = [];
    for i in range(len(arr)) {
        if (arr[i] not in unique_elements) {
            unique_elements.append(arr[i]);
        }
    }
    return unique_elements;
}



with entry {
    print(custom_sort([81]));
    print(custom_sort([]));
    print(custom_sort(['a']));
}
