def sum_greater_than_10_not_divisible_by_3(numbers: Any) -> object {
    total = 0;
    for number in numbers {
        if ((number > 10) and ((number % 3) != 0)) {
            total += number;
        }
    }
    return total;
}



with entry {
    print(sum_greater_than_10_not_divisible_by_3([1, 2, 4]));
    print(sum_greater_than_10_not_divisible_by_3([10, 20, 30]));
}
