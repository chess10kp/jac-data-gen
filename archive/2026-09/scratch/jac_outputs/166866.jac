"""is_prime will return if a number is prime or not."""
def is_prime(num: int) -> bool {
    if num == 0 or num == 1 {
        return False;
    }
    for i in range(2, num) {
        if num % i == 0 {
            return False;
        }
    }
    return True;
}