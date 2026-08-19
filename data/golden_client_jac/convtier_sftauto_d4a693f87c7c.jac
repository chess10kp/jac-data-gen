def sort_negative(arr: Any) -> object {
    n = len(arr);
    for i in range(n) {
        min_neg_index = i;
        if (arr[min_neg_index] >= 0) {
            continue;
        }
        for j in range((i + 1), n) {
            if ((arr[j] < 0) and (arr[j] < arr[min_neg_index])) {
                min_neg_index = j;
            }
        }
        if (min_neg_index != i) {
            (arr[i], arr[min_neg_index]) = (arr[min_neg_index], arr[i]);
        }
    }
    return arr;
}



with entry {
    print(sort_negative([81]));
    print(sort_negative([]));
    print(sort_negative([100]));
}
