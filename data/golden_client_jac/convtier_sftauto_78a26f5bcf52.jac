def compute_factorial_recursive(n: Any) -> object {
    if (not isinstance(n, int) or (n < 0)) {
        raise ValueError("Input must be a non-negative integer");
    }
    if (n > 10) {
        raise FactorialOutOfRangeError(
            "Factorial calculation is limited to the range of 0 to 10"
        );
    }
    if (n == 0) {
        return 1;
    } else {
        return (n * compute_factorial_recursive((n - 1)));
    }
}



with entry {
    print(compute_factorial_recursive(0));
}
