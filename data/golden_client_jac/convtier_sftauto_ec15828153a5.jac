def factorial(n: Any) -> object {
    if ((n == 0) or (n == 1)) {
        return 1;
    }
    if (n in factorial_cache) {
        return factorial_cache[n];
    }
    factorial_value = n * factorial((n - 1));
    factorial_cache[n] = factorial_value;
    return factorial_value;
}



with entry {
    print(factorial(0));
}
