"""
    No-one likes timing attacks.

    This function should probably not be part of the public API, and thus will
    be deprecated in a future release to be replaced with a internal function.
    """
def time_independent_HMAC_compare(a: str, b: str) -> bool {
    if len(a) != len(b) {
        return False;
    }
    result = 0;
    (a, b) = (a.lower(), b.lower());
    for i in range(len(a)) {
        result |= ord(a[i]) ^ ord(b[i]);
    }
    return result == 0;
}