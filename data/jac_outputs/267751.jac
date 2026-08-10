"""The number of letters which can be skipped (i.e. not being incremented
one by one) depending on the number of distinct letter pairs present."""
def digits_to_skip(distinct_letter_pairs: int) -> int {
    if distinct_letter_pairs == 0 {
        return 2;
    }
    return 0;
}