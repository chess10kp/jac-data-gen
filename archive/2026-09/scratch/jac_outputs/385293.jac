"""Checks if the two strings are anagram or not."""
def anagram1(S1: str, S2: str) -> bool {
    S1 = S1.replace(' ', '').lower();
    S2 = S2.replace(' ', '').lower();
    if len(S1) != len(S2) {
        return False;
    }
    count: dict[str, int] = {};
    for x in S1 {
        count[x] = count.get(x, 0) + 1;
    }
    for x in S2 {
        if x in count {
            count[x] -= 1;
        } else {
            count[x] = 1;
        }
    }
    return all(count[i] == 0 for i in count);
}