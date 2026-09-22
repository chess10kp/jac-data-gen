"""Returns True if the number is a sum of two discrete numbers in the preceding sequence."""
def is_valid(sequence: list[int], number: int) -> bool {
    for (i, num) in enumerate(sequence) {
        if (number - num) in sequence[i:] {
            return True;
        }
    }
    return False;
}