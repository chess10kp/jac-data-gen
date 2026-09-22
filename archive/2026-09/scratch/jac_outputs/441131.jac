"""Find if the number passed is even; False for non-positive numbers."""
def is_even(number: int) -> bool {
    if number <= 0 {
        return False;
    }
    return number % 2 == 0;
}