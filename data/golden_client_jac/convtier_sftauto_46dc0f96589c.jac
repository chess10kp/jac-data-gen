def calculate_sum(numbers: Any) -> object {
    try {
        total_sum = 0;
        for number in numbers {
            total_sum += float(number);
        }
        return total_sum;
    } except (TypeError, ValueError) {
        return "Invalid input! Please provide a valid list of numbers.";
    }
}



with entry {
    print(calculate_sum('hello'));
    print(calculate_sum([]));
    print(calculate_sum([1296, -10368]));
}
