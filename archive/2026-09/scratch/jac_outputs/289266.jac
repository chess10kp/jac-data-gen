"""
    Turns the abbreviated cigar into the full array

    0 = M
    1 = I
    2 = D
    """
def expandCigar(cigar: Any) -> object {
    ret = [];
    for (t, s) in cigar {
        ret.extend(([t] * s));
    }
    return ret;
}