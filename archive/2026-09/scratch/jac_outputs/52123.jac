"""
        Returns true is the number is prime.
        To check if a number is prime, we need to check
        all its divisors upto only sqrt(number).
        Reference: https://stackoverflow.com/a/5811176/7213370
    """
def is_prime(num: int) -> bool {
    if num == 1 {
        return False;
    }
    i = 2;
    while i * i <= num {
        if num % i == 0 {
            return False;
        }
        i += 1;
    }
    return True;
}