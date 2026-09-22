"""Return True if the number is prime, False otherwise."""
def is_prime(number: int) -> bool {
    for index in range(2, (number // 2) + 1) {
        if number % index == 0 {
            return False;
        }
    }
    return True;
}