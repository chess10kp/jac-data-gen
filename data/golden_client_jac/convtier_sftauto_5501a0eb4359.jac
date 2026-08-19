def is_prime(N: Any) -> object {
    if (N < 2) {
        return False;
    }
    for i in range(2, (int(math.sqrt(N)) + 1)) {
        if ((N % i) == 0) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_prime(0));
}
