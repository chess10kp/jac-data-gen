def is_prime(num: Any) -> object {
    if (num <= 1) {
        return False;
    }
    if (num == 2) {
        return True;
    }
    if ((num % 2) == 0) {
        return False;
    }
    for i in range(3, (int((num ** 0.5)) + 1), 2) {
        if ((num % i) == 0) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_prime(5));
    print(is_prime(10));
}
