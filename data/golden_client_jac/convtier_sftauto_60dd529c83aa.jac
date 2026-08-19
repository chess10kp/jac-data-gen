def sum_even_recursive(n: Any) -> object {
    if (n <= 0) {
        return 0;
    } elif ((n % 2) == 0) {
        return (n + sum_even_recursive((n - 2)));
    } else {
        return sum_even_recursive((n - 1));
    }
}



with entry {
    print(sum_even_recursive(0));
}
