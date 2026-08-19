def factorial(n: Any) -> object {
    if (not isinstance(n, int) or (n < 0)) {
        raise ValueError("n must be a positive integer");
    }
    if (n == 0) {
        return 1;
    }
    return (n * factorial((n - 1)));
}



with entry {
    print(factorial(0));
}
