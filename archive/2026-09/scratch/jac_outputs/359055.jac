"""Takes a list of ints and makes it into a string"""
def ListToStr(val: list[int]) -> str {
    return ''.join(['%c' % c for c in val]);
}