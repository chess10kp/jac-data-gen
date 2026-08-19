def is_prime(n: Any) -> object {
    if (n < 2) {
        return False;
    }
    if (n == 2) {
        return True;
    }
    if ((n % 2) == 0) {
        return False;
    }
    i = 3;
    while (i <= math.isqrt(n)) {
        if ((n % i) == 0) {
            return False;
        }
        i += 2;
    }
    return True;
}



with entry {
    print(is_prime(10));
    print(is_prime(2));
}
