def factorial(n: Any) -> object {
    if (not isinstance(n, int) or (n < 0)) {
        raise ValueError("Input must be a non-negative integer");
    }
    if (n <= 1) {
        return 1;
    } else {
        return (n * factorial((n - 1)));
    }
}



with entry {
    print(factorial(0));
}
