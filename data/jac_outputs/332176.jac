"""
What comes in:  A sequence of integers.
What goes out: Returns the sum of the numbers in the given sequence.
Side effects: None.
"""
def sum_sequence(sequence: list[int] | tuple[int, ...]) -> int {
    total = 0;
    for k in sequence {
        total = total + k;
    }
    return total;
}