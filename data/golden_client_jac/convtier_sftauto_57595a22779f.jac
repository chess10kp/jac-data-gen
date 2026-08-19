def calculate_sum(numbers: Any) -> object {
    sum = 0;
    for num in numbers {
        sum += num;
    }
    return sum;
}



with entry {
    print(calculate_sum([]));
    print(calculate_sum([6, -12]));
}
