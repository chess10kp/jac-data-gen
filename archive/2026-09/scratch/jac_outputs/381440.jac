""" Returns True if the considered string is a valid RIPEMD160 hash. """
def is_hash160(s: str) -> bool {
    if not s or not isinstance(s, str) {
        return False;
    }
    if len(s) != 40 {
        return False;
    }
    for c in s {
        if (
            (c < '0' or c > '9')
            and (c < 'A' or c > 'F')
            and (c < 'a' or c > 'f')
        ) {
            return False;
        }
    }
    return True;
}