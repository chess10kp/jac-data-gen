"""Distance is 0 if the pronoun and antecedent are in the same sentence."""
def distance_pronoun_antecedent(pair: list[int]) -> int {
    return pair[3] - pair[2];
}