"""Search for vowels in entered word."""
def search_for_vowels(phrase: str) -> set[str] {
    return set('aeiou').intersection(set(phrase));
}