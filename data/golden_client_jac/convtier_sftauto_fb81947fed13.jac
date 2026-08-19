def is_power_of_two(n: Any) -> object {
    if (n <= 0) {
        return False;
    }
    while (n > 1) {
        if ((n % 2) != 0) {
            return False;
        }
        n = n / 2;
    }
    return True;
}



with entry {
    print(is_power_of_two(5));
    print(is_power_of_two(2));
}
