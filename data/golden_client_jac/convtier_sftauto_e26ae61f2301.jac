def sum_exclude_multiples_of_three(numbers: Any) -> object {
    sum = 0;
    for num in numbers {
        if ((num % 3) != 0) {
            sum += num;
        }
    }
    return sum;
}



with entry {
    print(sum_exclude_multiples_of_three([]));
}
