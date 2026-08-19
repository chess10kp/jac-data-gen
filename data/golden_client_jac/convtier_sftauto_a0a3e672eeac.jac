def sum_even_numbers(arr: Any) -> object {
    total = 0;
    for num in arr {
        if ((num % 2) == 0) {
            total += num;
        }
    }
    return total;
}



with entry {
    print(sum_even_numbers([]));
}
