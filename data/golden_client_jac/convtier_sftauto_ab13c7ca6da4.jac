def find_minimum_value(arr: Any) -> object {
    if (len(arr) == 0) {
        return "Error: The array is empty.";
    }
    min_value = float('inf');
    for num in arr {
        if (num < min_value) {
            min_value = num;
        }
    }
    return min_value;
}



with entry {
    print(find_minimum_value([]));
    print(find_minimum_value([6, -12]));
}
