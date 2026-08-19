def filter_even(numbers: Any) -> object {
    even_numbers = [];
    for num in numbers {
        if ((num % 2) == 0) {
            even_numbers.append(num);
        }
    }
    return even_numbers;
}



with entry {
    print(filter_even([81]));
    print(filter_even([100]));
    print(filter_even([-8, -4, 2]));
}
