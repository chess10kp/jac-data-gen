"""Find an anagram of the string that is palindrome."""
def palindrome_anagram(S: str) -> bool {
    visited = set();
    for s in S {
        if s in visited {
            visited.remove(s);
        } else {
            visited.add(s);
        }
    }
    return len(visited) <= 1;
}