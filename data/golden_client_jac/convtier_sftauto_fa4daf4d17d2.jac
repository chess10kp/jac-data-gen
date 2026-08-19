def is_prime(n: Any) -> object {
    if (n <= 1) {
        return False;
    }
    if (n == 2) {
        return True;
    }
    if ((n % 2) == 0) {
        return False;
    }
    sqrt_n = int(math.sqrt(n)) + 1;
    for i in range(3, sqrt_n, 2) {
        if ((n % i) == 0) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_prime(10));
    print(is_prime(2));
}
