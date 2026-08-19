def is_prime(n: Any) -> object {
    if (n <= 1) {
        return False;
    }
    for i in range(2, (int((n ** 0.5)) + 1)) {
        if ((n % i) == 0) {
            return True;
        }
    }
    return False;
}



with entry {
    print(is_prime(5));
    print(is_prime(10));
}
