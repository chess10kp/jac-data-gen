"""Given two strings s and t, determine if they are isomorphic.
Two strings s and t are isomorphic if the characters in s can be replaced to get t.
All occurrences of a character must be replaced with another character while preserving
the order of characters. No two characters may map to the same character, but a character
may map to itself."""
def isIsomorphic(s: str, t: str) -> bool {
    if len(set(s)) != len(set(t)) {
        return False;
    }
    result: dict[str, str] = {};
    for (i, ch) in enumerate(s) {
        if ch not in result {
            result[ch] = t[i];
        } elif result[ch] != t[i] {
            return False;
        }
    }
    return True;
}