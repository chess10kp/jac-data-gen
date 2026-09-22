"""
    Tries to determine if a buffer is empty.

    @type buffer: str
    @param buffer: Buffer to test if it is empty.

    @rtype: bool
    @return: C{True} if the given buffer is empty, i.e. full of zeros,
        C{False} if it doesn't.
    """
def allZero(buffer: Any) -> object {
    allZero = True;
    for byte in buffer {
        if (byte != 0) {
            allZero = False;
            break;
        }
    }
    return allZero;
}