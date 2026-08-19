def sum_of_even_numbers(lst: Any) -> object {
    total_sum = 0;
    for num in lst {
        if ((num % 2) == 0) {
            total_sum += num;
        }
    }
    return total_sum;
}



with entry {
    print(sum_of_even_numbers([]));
}
