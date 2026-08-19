def sum_odd_numbers(numbers: Any) -> object {
    total = 0;
    for num in numbers {
        if ((num % 2) != 0) {
            total += num;
        }
    }
    return total;
}



with entry {
    print(sum_odd_numbers([]));
}
