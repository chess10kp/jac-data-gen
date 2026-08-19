def calculate_sum(numbers: Any) -> object {
    for num in numbers {
        if (not isinstance(num, int) or (num < 0)) {
            raise ValueError("All numbers must be positive integers");
        }
    }
    sum_result = sum(numbers);
    rounded_sum = round(sum_result);
    return rounded_sum;
}



with entry {
    print(calculate_sum([]));
    print(calculate_sum([10, 20]));
}
