"""Compare function used to sort top 250/bottom 10 rank."""
def _cmpTop(a: tuple[str, dict[str, str]], b: tuple[str, dict[str, str]], what: str = 'top 250 rank') -> int {
    av = int(a[1].get(what));
    bv = int(b[1].get(what));
    if av == bv {
        return 0;
    }
    return (-1, 1)[av > bv];
}