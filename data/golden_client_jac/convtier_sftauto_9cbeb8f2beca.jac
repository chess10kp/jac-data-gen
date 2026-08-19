def power_of_two(n: Any) -> object {
    result = 1;
    base = 2;
    while (n > 0) {
        if ((n % 2) == 1) {
            result *= base;
        }
        base *= base;
        n //= 2;
    }
    return result;
}



with entry {
    print(power_of_two(5));
    print(power_of_two(10));
    print(power_of_two(2));
}
