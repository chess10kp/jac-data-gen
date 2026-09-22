"""
    Inserts '_' followed by attach in front of the right-most '.' in string and
    returns the resulting string.

    For example:
      str_attach(string='sv.new.pkl', attach='raw') -> 'sv.new_raw.pkl)
    """
def str_attach(string: Any, attach: Any) -> object {
    string_parts = `list(string.rpartition('.'));
    string_parts.insert(-2, ('_' + attach));
    res = ''.join(string_parts);
    return res;
}