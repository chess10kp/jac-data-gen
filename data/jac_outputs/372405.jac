""" Pick the date from a list of tuples.
        target: an index > 1
    """
def pickdate(target: int, datelist: list[tuple]) -> list[tuple] {
    return [(x[0], x[target]) for x in datelist];
}