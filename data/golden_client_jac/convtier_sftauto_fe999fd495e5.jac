"""Helper function to check if a number is prime"""
def is_prime(n: Any) -> object {
    if (n < 2) {
        return False;
    }
    for i in range(2, (int((n ** 0.5)) + 1)) {
        if ((n % i) == 0) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_prime(5));
    print(is_prime(10));
}
