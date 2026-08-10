"""In : N (consistent NFA)
            q (state in N)
            c (symbol in N's sigma or "")
       Out: The set of states reached via N's Delta.
       EClosure is NOT performed.
       If the move is not defined, return {}.
    """
def step_nfa(N: dict[str, object], q: object, c: str) -> set[object] {
    assert c in (N["Sigma"] | {""}), "c given to step_nfa not in Sigma.";
    assert q in N["Q"], "q given to step_nfa not in Q.";
    if (q, c) in N["Delta"] {
        return N["Delta"][(q, c)] as set[object];
    }
    return set();
}