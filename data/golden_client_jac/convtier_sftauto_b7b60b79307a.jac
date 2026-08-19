"""Check if a number is prime."""
def is_prime(num: Any) -> object {
    if (num <= 1) {
        return False;
    }
    for i in range(2, (int((num ** 0.5)) + 1)) {
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
