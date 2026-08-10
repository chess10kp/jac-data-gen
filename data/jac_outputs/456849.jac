""" Assumes num > 3 """
def is_prime(num: Any) -> object {
    if ((num % 2) == 0) {
        return False;
    }
    for p in range(3, (int((num ** 0.5)) + 1), 2) {
        if ((num % p) == 0) {
            return False;
        }
    }
    return True;
}