"""
isSpace :: str -> bool

Returns True for any Unicode space character, and the control characters
\t, \n, \r, \f, \v.
"""
def isSpace(s: str) -> bool {
    return s in " \t\n\r\f\v";
}