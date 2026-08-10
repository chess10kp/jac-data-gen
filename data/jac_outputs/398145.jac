"""Return the input if odd, or input + 1 if even or zero."""
def make_odd(number: int) -> int {
    if number == 0 {
        number += 1;
    }
    if number % 2 == 0 {
        number += -1;
    }
    return number;
}