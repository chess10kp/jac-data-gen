"""Calculate the number of correctly overlapping chunks in the two sets."""
def get_ncor(gold_chunks: list[str], guess_chunks: list[str]) -> set[str] {
    return set(x for x in list(set(gold_chunks) & set(guess_chunks)));
}