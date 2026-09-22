"""Given a list of bytestrings and NamedInts, return the total
       length of all items in the list.
    """
def findLength(lst: list[bytes]) -> int {
    return sum(len(item) for item in lst);
}