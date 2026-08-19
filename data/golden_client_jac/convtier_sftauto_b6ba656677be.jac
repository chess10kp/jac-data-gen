def sum_greater_than_five(numbers: Any) -> object {
    total = 0;
    for num in numbers {
        if (num > 5) {
            total += num;
        }
    }
    return total;
}



with entry {
    print(sum_greater_than_five([]));
}
