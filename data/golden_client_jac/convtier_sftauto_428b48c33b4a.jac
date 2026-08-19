def calculate_sum(string: Any) -> object {
    try {
        integers = string.split(',');
        total_sum = 0;
        for num in integers {
            if is_prime(int(num)) {
                total_sum += num;
            }
        }
        return total_sum;
    } except Exception as e {
        return "Error: Invalid input";
    }
}



with entry {
    print(calculate_sum('hello'));
}
