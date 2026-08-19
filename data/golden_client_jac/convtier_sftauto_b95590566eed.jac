def sum_of_positive_numbers(numbers: Any) -> object {
    positive_sum = 0;
    for num in numbers {
        if (num > 0) {
            positive_sum += num;
        }
    }
    return positive_sum;
}



with entry {
    print(sum_of_positive_numbers([]));
}
