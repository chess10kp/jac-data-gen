"""
    Function to reveal hidden similarity edges between tweet-nodes based on
    SimHash, an LSH approximation on TF-IDF vectors and a cosine similarity
    threshold.

    Returns:
        A list with all triples made by consecutive words in a sentence.
    """
def get_shingles(sentence: str, n: int) -> list[str] {
    s = sentence.lower();
    return [s[i:(i + n)] for i in range(max(((len(s) - n) + 1), 1))];
}