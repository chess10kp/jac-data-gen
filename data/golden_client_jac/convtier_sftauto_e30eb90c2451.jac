def count_max_occurrences(arr: Any) -> object {
    max_val = float('-inf');
    max_count = 0;
    for row in arr {
        for num in row {
            if (num > max_val) {
                max_val = num;
                max_count = 1;
            } elif (num == max_val) {
                max_count += 1;
            }
        }
    }
    return max_count;
}



with entry {
    print(count_max_occurrences([]));
}
