def merge_sort(numbers: Any) -> object {
    if (len(numbers) <= 1) {
        return numbers;
    }
    mid = len(numbers) // 2;
    left_half = numbers[:mid];
    right_half = numbers[mid:];
    left_half = merge_sort(left_half);
    right_half = merge_sort(right_half);
    return merge(left_half, right_half);
}



with entry {
    print(merge_sort([]));
}
