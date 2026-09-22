"""
    Partition a string into all possible two parts, e.g.
    given "abcd", generate [("a", "bcd"), ("ab", "cd"), ("abc", "d")]
    For string of length 1, return empty list
    """
def genSubparts(string: Any) -> object {
    length = len(string);
    res = [];
    for i in range(1, length) {
        res.append((string[0:i], string[i:]));
    }
    return res;
}