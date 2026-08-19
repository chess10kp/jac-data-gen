def factorial(n: Any) -> object {
    if (not isinstance(n, int) or (n < 0)) {
        return "Factorial is undefined for negative numbers and non-integers.";
    }
    if (n == 0) {
        return 1;
    }
    return (n * factorial((n - 1)));
}



with entry {
    print(factorial('hello'));
    print(factorial(0));
}
