"""
    Find the index of a letter in a word starting the search at specific index
    """
def find(word: str, letter: str, start_index: int) -> int {
    index = start_index;
    while index < len(word) {
        if word[index] == letter {
            return index;
        }
        index += 1;
    }
    return -1;
}