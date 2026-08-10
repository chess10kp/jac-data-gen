"""Finds whether time best corresponds to a value in
    days, hours, minutes, or seconds.
    """
def find_dividend_by_unit(time: Any) -> object {
    for dividend in [86400, 3600, 60] {
        div = time / dividend;
        if (round(div) == div) {
            return dividend;
        }
    }
    return 1;
}