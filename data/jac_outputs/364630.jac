"""Check whether word is a palindrome."""
def is_palin(word: str) -> bool {
    return word[::-1] == word;
}