"""
    Flag whether a word experiment_results
    """
def count_words(sent: str, dictionary: dict[str, object]) -> bool {
    words = str(sent).split();
    return any(w in words for w in dictionary);
}