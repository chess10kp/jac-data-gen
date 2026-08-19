def sum_of_odd_numbers(n: Any) -> object {
    total_sum = 0;
    count_divisible = 0;
    for i in range(1, ((2 * n) + 1), 2) {
        if (((i % 3) == 0) and ((i % 5) == 0)) {
            count_divisible += 1;
        } else {
            total_sum += i;
        }
    }
    return (total_sum % ((10 ** 9) + 7));
}



with entry {
    print(sum_of_odd_numbers(5));
    print(sum_of_odd_numbers(10));
    print(sum_of_odd_numbers(2));
}
