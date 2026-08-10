"""
    Given a string, recursively returns a reversed copy of the string.
    For example, if the string is 'abc', the function returns 'cba'.
    The only string operations you are allowed to use are indexing,
    slicing, and concatenation.

    string: a string
    returns: a reversed string
    """
def reverse_string(string: Any) -> object {
    if (string == "") {
        return "";
    } else {
        return (string[-1] + reverse_string(string[:-1]));
    }
}