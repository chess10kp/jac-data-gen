def factorial(n: Any) -> object {
    if (isinstance(n, float) or isinstance(n, str)) {
        raise TypeError("Input must be an integer");
    }
    if (n < 0) {
        raise ValueError("Input must be a non-negative integer");
    }
    if ((n == 0) or (n == 1)) {
        return 1;
    } else {
        return (n * factorial((n - 1)));
    }
}



with entry {
    print(factorial(0));
}
