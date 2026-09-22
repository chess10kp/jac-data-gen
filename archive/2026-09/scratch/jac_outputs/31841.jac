""" Is number or not
    """
def isnumber(s: str | int | float) -> bool {
    try {
        _ = int(s);
        return True;
    } except ValueError {
        return False;
    }
}