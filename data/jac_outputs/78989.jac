"""Return True if there are no duplicate elements in sequence seq."""
def unique(seq: list[int | str]) -> bool {
    for i in range(len(seq)) {
        for j in range(i + 1, len(seq)) {
            if seq[i] == seq[j] {
                return False;
            }
        }
    }
    return True;
}