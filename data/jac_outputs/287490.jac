""" Format function for Matplotlib formatter. """
def formatFreq(value: float, pos: int) -> str {
    inv = 999.0;
    if value {
        inv = 1 / value;
    }
    return "1/%0.2f" % inv;
}