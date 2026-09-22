"""Return all permutations of the input list."""
def permutation(s: list[int]) -> list[list[int]] {
    ret = [];
    length = len(s);
    if length == 0 {
        return ret;
    }
    if length == 1 {
        return [s];
    }
    curr = s[0];
    for prev in permutation(s[1:]) {
        for i in range(length) {
            ret.append(prev[:i] + [curr] + prev[i:]);
        }
    }
    return ret;
}