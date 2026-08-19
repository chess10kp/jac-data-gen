def is_prime(num: Any) -> object {
    if ((`type(num) != int) or (num < 0)) {
        return False;
    }
    if (num == 2) {
        return True;
    }
    if ((num < 2) or ((num % 2) == 0)) {
        return False;
    }
    for i in range(3, (int(math.sqrt(num)) + 1), 2) {
        if ((num % i) == 0) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_prime('hello'));
    print(is_prime(2));
}
