def sum_even_numbers(numbers: Any) -> object {
    total = 0;
    i = 0;
    while (i < len(numbers)) {
        if ((numbers[i] % 2) == 0) {
            total += numbers[i];
        }
        i += 1;
    }
    return total;
}



with entry {
    print(sum_even_numbers([]));
}
