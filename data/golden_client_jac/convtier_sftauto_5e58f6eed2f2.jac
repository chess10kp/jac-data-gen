def get_even_numbers(arr: Any) -> object {
    even_numbers = [];
    for num in arr {
        if ((num % 2) == 0) {
            even_numbers.append(num);
        }
    }
    even_numbers.sort();
    return even_numbers;
}



with entry {
    print(get_even_numbers([]));
}
