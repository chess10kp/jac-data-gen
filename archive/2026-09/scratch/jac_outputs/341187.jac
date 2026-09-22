"""Calculate Petzval sum of a multi-element lens.

    Args:
        ns (sequence): Refractive indices of all media.
        rocs (sequence): Length is one less than ns.

    Returns:
        Petzval sum.
    """
def calc_multi_element_lens_petzval_sum(ns: list[float], rocs: list[float]) -> float {
    assert len(ns) == len(rocs) + 1;
    ps = 0.0;
    for (n1, n2, roc) in zip(ns[:-1], ns[1:], rocs) {
        ps += (n2 - n1) / (roc * n1 * n2);
    }
    return ps;
}