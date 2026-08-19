def factorial(n: Any) -> object {
    if (n == 0) {
        return 1;
    } else {
        return (n * factorial(n));
    }
}



with entry {
    print(factorial(0));
}
