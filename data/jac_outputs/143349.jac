"""Returns the number of iterations of a given word in a bag of words."""
def freq_in_doc(word: str, doc_bow: dict[str, int]) -> int {
    return doc_bow.get(word, 0);
}