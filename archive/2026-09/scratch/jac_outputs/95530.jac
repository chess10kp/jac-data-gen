"""
    Return the prefix for the given headword,
    of length length.

    :param headword: the headword string
    :type  headword: unicode
    :param length: prefix length
    :type  length: int
    :rtype: unicode
    """
def get_prefix(headword: Any, length: Any) -> object {
    if (headword is None) {
        return None;
    }
    lowercased = headword.lower();
    if (ord(lowercased[0]) < 97) {
        return "SPECIAL";
    }
    if (len(lowercased) < length) {
        return lowercased;
    }
    return lowercased[0:length];
}