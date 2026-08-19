def calculate_sum(input_array: Any) -> object {
    total_sum = 0;
    for num in input_array {
        total_sum += num;
    }
    return total_sum;
}



with entry {
    print(calculate_sum([]));
}
