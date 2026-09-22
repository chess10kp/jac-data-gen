"""
    Return minimum number of precincts that could be "bad".
       L = list of n precincts: n (size,name) pairs
       M = margin of victory as number of votes separating winner
           from runner-up
       s = maximum within-precinct miscount
    """
def bmin(L: list[tuple[int, str]], M: int, s: float = 0.2) -> int {
    assert 0 <= M <= sum(x[0] for x in L);
    votes_so_far = 0.0;
    k = 0;
    while votes_so_far < M and k < len(L) {
        votes_so_far += 2.0 * s * L[k][0];
        k += 1;
    }
    return k;
}