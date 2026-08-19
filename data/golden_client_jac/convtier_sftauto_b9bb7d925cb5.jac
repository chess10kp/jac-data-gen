def factorial(n: Any) -> object {
    if (not isinstance(n, int) or (n <= 0)) {
        return "Error: Input must be a positive integer";
    }
    if (n == 1) {
        return 1;
    }
    if (n > (sys.getrecursionlimit() / 2)) {
        return large_factorial(n);
    } else {
        return (n * factorial((n - 1)));
    }
}



with entry {
    print(factorial('hello'));
    print(factorial(1));
}
