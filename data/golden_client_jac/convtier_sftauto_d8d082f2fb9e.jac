def find_largest_number(arr: Any) -> object {
    max_num = 0;
    for num in arr {
        if (num < 0) {
            return "Error: Negative numbers are not allowed.";
        }
        if (num > max_num) {
            max_num = num;
        }
    }
    return max_num;
}



with entry {
    print(find_largest_number([]));
}
