def find_odd_occurrence(arr: Any) -> object {
    result = 0;
    for num in arr {
        result ^= num;
    }
    for (i, num) in enumerate(arr) {
        if (num == result) {
            return i;
        }
    }
}



with entry {
    print(find_odd_occurrence([2]));
    print(find_odd_occurrence([2, 4, 6, 8]));
    print(find_odd_occurrence([4, 2, 7, 1, 9]));
}
