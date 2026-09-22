"""returns the position immediately _after_ the end of the occurence
    of str2 in str1.  If str2 is not in str1, return -1.
    """
def posofend(str1: str, str2: str) -> int {
    pos = str1.find(str2);
    return pos + len(str2) if pos > -1 else -1;
}