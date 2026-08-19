def is_prime(number: Any) -> object {
    if (number < 2) {
        return False;
    }
    for i in range(2, (int(math.sqrt(number)) + 1)) {
        if ((number % i) == 0) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_prime(0));
}
