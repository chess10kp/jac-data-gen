"""Convert a list of tuples into a simple list of tuple[0] items."""
def listOfTuplesToList(listOfTuples: list[tuple[int, int]]) -> list[int] {
    return [item[0] for item in listOfTuples];
}