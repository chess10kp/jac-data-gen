""" Parse the TLD of a domain name.

    :param s: String to parse.
    """
def tld(s: Any) -> object {
    if s.endswith('.') {
        return s[(s.rfind('.', 0, -1) + 1):-1];
    }
    return s[(s.rfind('.') + 1):];
}