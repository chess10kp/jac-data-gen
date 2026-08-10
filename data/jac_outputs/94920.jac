"""Usage: Find the nth term of a sequence."""
def sequence_nth(first_term: int, term_number: int, common_difference: int) -> int {
    first_term + common_difference * (term_number - 1)
}