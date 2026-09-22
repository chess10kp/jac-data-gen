"""Removes surrogate pairs from a Unicode string."""
def stripSurrogatePairs(ustring: str) -> str {
    try {
        ustring.encode('utf-8');
    } except UnicodeEncodeError {
        tmp = ustring.encode('utf-8', 'replace');
        ustring = tmp.decode('utf-8', 'ignore');
    }
    return ustring;
}