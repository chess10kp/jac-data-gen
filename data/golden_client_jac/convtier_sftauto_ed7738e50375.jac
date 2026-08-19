def mergeSort(records: Any) -> object {
    if (len(records) <= 1) {
        return records;
    }
    middle = len(records) // 2;
    left_half = records[:middle];
    right_half = records[middle:];
    sorted_left = mergeSort(left_half);
    sorted_right = mergeSort(right_half);
    return merge(sorted_left, sorted_right);
}



with entry {
    print(mergeSort([81]));
    print(mergeSort([]));
    print(mergeSort(['a']));
}
