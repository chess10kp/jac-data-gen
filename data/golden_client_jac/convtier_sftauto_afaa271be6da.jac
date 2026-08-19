def sum_of_even_numbers(lst: Any) -> object {
    sum = 0;
    for num in lst {
        if ((num % 2) == 0) {
            sum += num;
        }
    }
    return sum;
}



with entry {
    print(sum_of_even_numbers([]));
}
