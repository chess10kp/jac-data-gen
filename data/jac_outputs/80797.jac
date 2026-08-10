"""
    Checks if a point is unhappy. Returns False if happy.
    """
def unhappy_point(`list: Any, index: Any) -> object {
    if (
        (`list[index] == `list[(index - 1)])
        or (`list[index] == `list[((index + 1) % len(`list))])
    ) {
        return False;
    }
    return True;
}