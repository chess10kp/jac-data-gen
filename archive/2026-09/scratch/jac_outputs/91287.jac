"""Count occurrences of a given bigram in a sequence."""
def count_bigram(sequence: str, first: str, second: str) -> int {
    count = 0;
    cmp = False;
    for char in sequence {
        if cmp {
            cmp = False;
            if char == second {
                count += 1;
            }
        }
        if char == first {
            cmp = True;
        }
    }
    return count;
}