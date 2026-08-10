"""
        Does this string have any non-ASCII characters?
    """
def isBin(s: str) -> bool {
    for ch in s {
        code = ord(ch);
        if code < 9 {
            return True;
        } elif code > 13 and code < 32 {
            return True;
        } elif code > 126 {
            return True;
        }
    }
    return False;
}