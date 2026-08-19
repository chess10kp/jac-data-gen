def factorial(n: Any) -> object {
    if (n == 0) {
        return 1;
    }
    return multiply(n, factorial(subtract(n, 1)));
}



with entry {
    print(factorial(0));
}
