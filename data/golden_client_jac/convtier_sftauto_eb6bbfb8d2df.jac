def calculate_even_sum(arr: Any) -> object {
    even_sum = 0;
    for num in arr {
        if ((num % 2) == 0) {
            even_sum += num;
        }
    }
    return even_sum;
}



with entry {
    print(calculate_even_sum([]));
    print(calculate_even_sum([-12, 6]));
    print(calculate_even_sum([-12, -6, -3, 21]));
}
