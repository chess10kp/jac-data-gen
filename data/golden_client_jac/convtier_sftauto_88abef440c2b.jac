def is_prime(num: Any) -> object {
    if (num < 2) {
        return False;
    }
    for i in range(2, (int(sqrt(num)) + 1)) {
        if ((num % i) == 0) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_prime(0));
}
