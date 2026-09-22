"""Checks if s1 and s2 are anagrams by counting occurrences of each letter."""
def isAnagram(s1: str, s2: str) -> bool {
    set1 = set(s1);
    set2 = set(s2);
    if set1 == set2 {
        for char in set1 {
            if s1.count(char) != s2.count(char) {
                return False;
            }
        }
    } else {
        return False;
    }
    return True;
}