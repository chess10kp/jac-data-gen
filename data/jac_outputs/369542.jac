"""Given a number x, returns True if it is prime; otherwise returns False."""
def is_prime(x: int | float | str | bool) -> bool {
    if x.__class__ != int {
        return False;
    }
    xi = x as int;
    num_factors = 0;
    for n in range(2, xi + 1) {
        if xi % n == 0 {
            num_factors += 1;
        }
    }
    return num_factors == 1;
}