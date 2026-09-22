"""find letter in word , return first occurence"""
def find(word: str, letter: str) -> int {
    for (index, ch) in enumerate(word) {
        if ch == letter {
            return index;
        }
    }
    return -1;
}