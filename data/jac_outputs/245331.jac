"""Return the dictionary id for a hyphen string, or 0 if not found."""
def hyp2id(hyp: str, dictionary: dict[str, int]) -> int {
    return dictionary[hyp] if hyp in dictionary else 0;
}