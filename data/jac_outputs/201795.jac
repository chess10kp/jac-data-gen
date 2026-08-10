"""Compare if two strings are anagrams using lists."""
def anagram_lst(str1: str, str2: str) -> bool {
    sorted(list(str1.lower())) == sorted(list(str2.lower()))
}