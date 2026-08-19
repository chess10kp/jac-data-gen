def factorial(n: int) -> int {
    result = 1;
    i = 2;
    while i <= n {
        result *= i;
        i += 1;
    }
    return result;
}

with entry {
    for x in [0, 1, 5, 7, 10] {
        print(factorial(x));
    }
}
