def calculate_sum(numbers: Any) -> object {
    total = 0;
    for num in numbers {
        total = total ^ num;
    }
    return total;
}



with entry {
    print(calculate_sum([0]));
    print(calculate_sum([2, -4, -8]));
    print(calculate_sum([7, -1, -4, -2]));
}
