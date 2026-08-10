"""
    Replace verbatim white space lien endings and tabs (\\n, \\r, \\t) that
    may exist as-is as literals in the extracted string by a space.
    """
def del_special(S: str) -> str {
    return S.replace('\\r', ' ').replace('\\n', ' ').replace('\\t', ' ');
}