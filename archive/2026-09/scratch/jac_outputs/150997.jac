"""Transform string to match name of a probability function."""
def get_canonical_prob_name(prob_name: str) -> str {
    prob_name = prob_name.lower();
    if not prob_name.endswith('_probability') {
        prob_name = prob_name + '_probability';
    }
    return prob_name;
}