def sum_even_numbers(numbers: Any) -> object {
    even_sum = 0;
    for number in numbers {
        if ((number % 2) == 0) {
            even_sum += number;
        }
    }
    return even_sum;
}



with entry {
    print(sum_even_numbers([]));
}
