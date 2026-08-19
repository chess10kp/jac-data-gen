def is_prime(n: Any) -> object {
    if (n <= 1) {
        return False;
    }
    for i in range(2, (int(math.sqrt(n)) + 1)) {
        if ((n % i) == 0) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_prime(0));
}
