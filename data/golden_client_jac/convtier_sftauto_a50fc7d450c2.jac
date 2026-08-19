def is_prime(n: Any) -> object {
    if (n <= 1) {
        return False;
    }
    if (n <= 3) {
        return True;
    }
    if (((n % 2) == 0) or ((n % 3) == 0)) {
        return False;
    }
    for i in range(5, (int(math.sqrt(n)) + 1), 6) {
        if (((n % i) == 0) or ((n % (i + 2)) == 0)) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_prime(10));
    print(is_prime(2));
}
