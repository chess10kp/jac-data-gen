"""Utility function to generate column names for the synthetic dataset."""
def generate_col_names(d: int) -> list[str] {
    assert d >= 6;
    pC = 2;
    pP = 2;
    pI = 2;
    pS = d - (pC + pI + pP);
    col_names = (
        ['A', 'Y']
        + [f'Xc{i}' for i in range(1, pC + 1)]
        + [f'Xp{i}' for i in range(1, pP + 1)]
        + [f'Xi{i}' for i in range(1, pI + 1)]
        + [f'Xs{i}' for i in range(1, pS + 1)]
    );
    return col_names;
}