def sum_of_numbers(n: Any) -> object {
    if (n <= 0) {
        return 0;
    } else {
        return (n + sum_of_numbers((n - 1)));
    }
}



with entry {
    print(sum_of_numbers(0));
}
