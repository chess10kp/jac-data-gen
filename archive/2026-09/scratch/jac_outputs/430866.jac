""" takes in a string s and return a string with no punctuation and no upper-case letters"""
def cleanString(s: str) -> str {
    s = s.lower();
    for p in "?.!,'" {
        s = s.replace(p, '');
    }
    return s;
}