"""
    Only true if string is one of "yes", "true", "t", "1". Returns false
    otherwise.
    """
def str2bool(string: str) -> bool {
    return string.lower() in ("yes", "true", "t", "1");
}