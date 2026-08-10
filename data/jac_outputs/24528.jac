"""Return Jaccard similarity between two word sets."""
def word_overlap(left_words: set[str], right_words: set[str]) -> float {
    intersection = len(left_words.intersection(right_words));
    union = len(left_words.union(right_words));
    return intersection / union;
}