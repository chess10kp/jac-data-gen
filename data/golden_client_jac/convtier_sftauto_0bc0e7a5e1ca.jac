def fibonacci_recursive(n: Any) -> object {
    if (n <= 1) {
        return n;
    } else {
        return (fibonacci_recursive((n - 1)) + fibonacci_recursive((n - 2)));
    }
}



with entry {
    print(fibonacci_recursive(0));
    print(fibonacci_recursive(1));
}
