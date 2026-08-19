def is_prime_and_divisible_by_seven(value: Any) -> object {
    if ((value <= 100) or ((value % 7) != 0)) {
        return False;
    }
    for i in range(2, (math.isqrt(value) + 1)) {
        if ((value % i) == 0) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_prime_and_divisible_by_seven(5));
}
