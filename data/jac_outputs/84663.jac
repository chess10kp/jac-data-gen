"""return coefficients for seasonal difference (1-L^s)

    just a trivial convenience function

    Parameters
    ----------
    s : int
        number of periods in season

    Returns
    -------
    sdiff : list, length s+1
    """
def lpol_sdiff(s: int) -> list[int] {
    [1] + ([0] * (s - 1)) + [-1]
}