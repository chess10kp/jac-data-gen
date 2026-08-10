"""Returns true if specified word is in the string."""
def find_whole_word(word: str, string: str) -> bool {
    return word in string.split();
}