"""Finds if bet is in between start and end

    Arguments:
        start {Integer}
        bet {Integer}
        end {Integer}

    Returns:
        Boolean -- True if it is in between, else False
    """
def circular_between(start: int, bet: int, end: int) -> bool | None {
    if end > start {
        return bet > start and bet < end;
    } elif end < start {
        return bet > start or bet < end;
    }
}