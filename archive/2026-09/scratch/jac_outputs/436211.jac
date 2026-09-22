"""
    bool('False') is True in Python, so we need to do some string parsing.  Use the same words in ConfigParser
    :param Text str:
    :rtype: bool
    """
def str2bool(str: Any) -> object {
    return not (str.lower() in ["false", "0", "off", "no"]);
}