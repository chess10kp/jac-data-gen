"""validate1(s, a): list comprehension with a.index"""
def validate1(s: list[str], a: list[str]) -> bool {
    try {
        [a.index(x) for x in s];
        return True;
    } except Exception {
        return False;
    }
}