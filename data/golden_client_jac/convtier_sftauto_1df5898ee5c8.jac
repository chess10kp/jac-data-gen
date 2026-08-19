def sum_divisible_by_3(numbers: Any) -> object {
    total = 0;
    for num in numbers {
        if (((num % 3) == 0) and (num < 100)) {
            total += num;
        }
    }
    return total;
}



with entry {
    print(sum_divisible_by_3([]));
}
