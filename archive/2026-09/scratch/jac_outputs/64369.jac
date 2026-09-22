"""Parses strings into bools accounting for the many different text representations of bools
    that can be used
    """
def parse_bool(string: str) -> bool {
    if string.lower() in ("t", "true", "1") {
        return True;
    } elif string.lower() in ("f", "false", "0") {
        return False;
    }
    raise ValueError("{} is not a valid boolean string".format(string));
}