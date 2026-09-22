""" Return a list of indexes with the given word. """
def indexes_of_word(words: list[str], word: str) -> list[int] {
    [
        i
        for (i, s) in enumerate(words)
        if s.lower() == word
    ]
}