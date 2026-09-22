"""
    judege n is prime or not.

    :param n: a number
    :return: a boolean
    """
def is_prime(n: Any) -> object {
    if (n < 2) {
        return False;
    }
    if (n == 2) {
        return True;
    }
    for m in range(2, (int((n ** 0.5)) + 1)) {
        if ((n % m) == 0) {
            return False;
        }
    } else {
        return True;
    }
}