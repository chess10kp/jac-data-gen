def get_even_numbers(numbers: Any) -> object {
    even_numbers = [];
    for num in numbers {
        if ((num % 2) == 0) {
            even_numbers.append(num);
        }
    }
    return even_numbers;
}



with entry {
    print(get_even_numbers([]));
}
