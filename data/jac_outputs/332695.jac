"""Convert a sequence of whitespace separated tokens
    each containing no more than 8 0's and 1's to a list of bytes.
    Raise Exception if illegal.
    """
def binEntryBytes(binStr: str) -> list[int] {
    bytes = [];
    for (i, token) in enumerate(binStr.split()) {
        if len(token) > 8 {
            raise Exception("Token {} is more than 8 bits: {}".format(i + 1, token));
        }
        bytes.append(int(token, 2));
    }
    return bytes;
}