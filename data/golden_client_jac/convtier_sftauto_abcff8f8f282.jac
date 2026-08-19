def is_odd_prime_number(array: Any) -> object {
    for num in array {
        if (((num % 2) != 0) and is_prime(num)) {
            return True;
        }
    }
    return False;
}



with entry {
    print(is_odd_prime_number([]));
}
