def factorial(n: Any) -> object {
    if (n == 0) {
        return 1;
    }
    if (n == 1) {
        return 1;
    }
    if (n == 2) {
        return 2;
    }
    return (n * factorial((n - 1)));
}



with entry {
    print(factorial(2));
    print(factorial(0));
}
