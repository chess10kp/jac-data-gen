def is_prime(n: Any) -> object {
    if (n < 2) {
        return False;
    }
    for i in range(2, ((n // 2) + 1)) {
        if ((n % i) == 0) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_prime(5));
    print(is_prime(10));
}
