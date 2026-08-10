"""creates a binary list, indicating inputlist entries are
between (inclusive) the minval and maxval"""
def getinrangelist(inputlist: list[int], minval: int, maxval: int) -> list[int] {
    return [1 if maxval >= i >= minval else 0 for i in inputlist];
}