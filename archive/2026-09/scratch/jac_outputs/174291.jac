"""Converts a comma-separated and new-line separated string into
    a list, stripping whitespace from both ends of each item.  Does not
    return any zero-length strings.
    """
def csnl_to_list(csnl_str: Any) -> object {
    s = csnl_str.replace('\n', ',');
    return [
        it.strip()
        for it in s.split(',')
        if it.strip()
    ];
}