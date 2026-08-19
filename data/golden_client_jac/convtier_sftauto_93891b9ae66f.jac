def is_prime(x: Any) -> object {
    if ((x == 1) or (x == 2)) {
        return True;
    }
    for i in range(2, (int((x ** 0.5)) + 1)) {
        if (((x // i) * i) == x) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_prime(5));
    print(is_prime(10));
}
