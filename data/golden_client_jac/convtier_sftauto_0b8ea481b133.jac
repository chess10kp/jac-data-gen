def is_prime(n: Any) -> object {
    if (n <= 1) {
        return False;
    }
    if ((n == 2) or (n == 3)) {
        return True;
    }
    if ((n % 2) == 0) {
        return False;
    }
    max_divisor = math.isqrt(n) + 1;
    for divisor in range(3, max_divisor, 2) {
        if ((n % divisor) == 0) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_prime(10));
    print(is_prime(2));
}
