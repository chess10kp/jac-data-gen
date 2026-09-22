"""Creates a map of letter use in a word.

    Args:
        word: a string to create a letter map from

    Returns:
        a dictionary of {letter: integer count of letter in word}
    """
def _letter_map(word: str) -> dict[str, int] {
    lmap = {};
    for letter in word {
        try {
            lmap[letter] += 1;
        } except KeyError {
            lmap[letter] = 1;
        }
    }
    return lmap;
}