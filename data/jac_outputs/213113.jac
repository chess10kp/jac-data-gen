"""Return True if word_1 and word_2 are anagrams."""
def is_anagram(word_1: str, word_2: str) -> bool {
    word_1.lower();
    word_2.lower();
    return sorted(word_1) == sorted(word_2);
}