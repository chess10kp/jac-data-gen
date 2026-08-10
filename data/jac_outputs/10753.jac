"""Given a collection of words, return the ones that are n letters."""
def n_letter_words(all_words: str, n: int) -> list[str] {
    return [word for word in all_words.split(" ") if len(word) == n];
}