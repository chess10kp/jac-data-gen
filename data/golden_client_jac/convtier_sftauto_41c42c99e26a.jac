def factorial(n: Any) -> object {
    if (n < 0) {
        raise ValueError("Factorial is not defined for negative numbers");
    }
    if not isinstance(n, int) {
        raise TypeError("Factorial is only defined for integers");
    }
    if ((n == 0) or (n == 1)) {
        return 1;
    }
    return (n * factorial((n - 1)));
}



with entry {
    print(factorial(0));
}
