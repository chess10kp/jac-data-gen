"""
    Returns the Number of minimum stocks per sector requiered to get to the nr_of_stocks with the selected sectors

    Args:
        nr_of_stocks (ind): Readout of the 'nr_of_stocks' input in the interface.
        sectors (list): List that is returned from the 'sectors' selectionbox in the interface

    Returns:
        mss (int): Number of minimum stocks per sector
        10 (int): If no sectors are selected it returns 10 as a default argument.
    """
def get_min_sec_stocks(nr_of_stocks: Any, sectors: Any) -> object {
    try {
        mss = int(round(((nr_of_stocks / len(sectors)) + 0.5)));
        return mss;
    } except ZeroDivisionError {
        return 10;
    }
}