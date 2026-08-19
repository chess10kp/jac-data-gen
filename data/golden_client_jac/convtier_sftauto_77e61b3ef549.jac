def calculate_sum(numbers: Any) -> object {
    total = 0;
    for num in numbers {
        if ((num % 3) != 0) {
            total += num;
        }
    }
    return total;
}



with entry {
    print(calculate_sum([]));
}
