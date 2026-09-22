"""
    Converts a contraction tree to a contraction path as returned by path
    optimizers. A contraction tree can be an int (=no contraction) or a tuple
    of terms to be contracted.
    """
def _tree_to_sequence(c: int | tuple) -> list[tuple[int, ...]] {
    if type(c) == int {
        return [];
    }
    stack = [c];
    t: list[int] = [];
    s: list[tuple[int, ...]] = [];
    while len(stack) > 0 {
        j = stack.pop(-1);
        s.insert(0, tuple());
        for i in sorted([i for i in j if type(i) == int]) {
            s[0] += (sum(1 for q in t if q < i), );
            t.insert(s[0][-1], i);
        }
        for i in [i for i in j if type(i) != int] {
            s[0] += (len(t) + len(stack), );
            stack.append(i);
        }
    }
    return s;
}