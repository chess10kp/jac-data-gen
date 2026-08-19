def factorial(n: int) -> int {
    result = n;
    i = 2;
    while i < n {
        result *= i;
        i += 1;
    }
    return result;
}
