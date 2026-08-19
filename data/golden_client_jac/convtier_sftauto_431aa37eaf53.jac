def sum_numbers(n: Any) -> object {
    if (n <= 0) {
        return 0;
    } elif ((n % 3) == 0) {
        return sum_numbers((n - 1));
    } else {
        return (n + sum_numbers((n - 1)));
    }
}



with entry {
    print(sum_numbers(0));
}
