"""Returns the number of times 8 appears as a digit of x."""
def num_eights(x: int) -> int {
    def is_eight(digit: int) -> int {
        return 1 if digit == 8 else 0;
    }
    if x < 10 {
        return is_eight(x);
    }
    return num_eights(x // 10) + is_eight(x % 10);
}