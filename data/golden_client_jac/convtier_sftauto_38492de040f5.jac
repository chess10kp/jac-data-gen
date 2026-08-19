def factorial(n: Any) -> object {
    return 1 if (n == 0) else (n * factorial((n - 1)));
}



with entry {
    print(factorial(0));
}
