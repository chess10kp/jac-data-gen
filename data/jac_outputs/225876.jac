"""Return True when every character in S is unique."""
def CharUnique(S: str) -> bool {
    for (i, _) in enumerate(S) {
        for c in range(i + 1, len(S)) {
            if S[i] == S[c] {
                return False;
            }
        }
    }
    return True;
}