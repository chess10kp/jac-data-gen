def count_consecutive_elements(arr: Any) -> object {
    if (len(arr) <= 1) {
        return len(arr);
    }
    max_count = 1;
    for subarr in arr {
        count = 1;
        for i in range(1, len(subarr)) {
            if (subarr[i] == subarr[(i - 1)]) {
                count += 1;
                max_count = max(max_count, count);
            } else {
                count = 1;
            }
        }
    }
    return max_count;
}



with entry {
    print(count_consecutive_elements('hello'));
}
