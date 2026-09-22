"""return True if the word use all the letters"""
def uses_all(word: Any, letters: Any) -> object {
    for letter in letters {
        if (letter not in word) {
            return False;
        }
    }
    return True;
}