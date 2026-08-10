"""
This algorithm finds an approximate solution
to finding a minimum collection of subsets
that cover the set X.

It is shown in lecture that this is a
(1 + log(n))-approximation algorithm.
"""
def set_cover(X: set[object], subsets: list[list[object]]) -> set[int] {
    cover = set();
    subsets_copy = list(subsets);
    while True {
        S = max(subsets_copy, key=len);
        if len(S) == 0 {
            break;
        }
        cover.add(subsets.index(S));
        subsets_copy.pop(subsets_copy.index(S));
        for x in S {
            for T in subsets_copy {
                if x in set(T) {
                    T.remove(x);
                }
            }
        }
    }
    return cover;
}