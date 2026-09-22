"""Splits string once on the first occurance of sep
    returns [head, tail] if succesful, and
    returns (string, None) if not.

    Intended for scenarios when using unpacking with an unknown string.
    """
def spl1n(string: str, sep: str) -> list[str] | tuple[str, None] {
    r = string.split(sep, 1);
    if len(r) > 1 {
        return r;
    } else {
        return (string, None);
    }
}