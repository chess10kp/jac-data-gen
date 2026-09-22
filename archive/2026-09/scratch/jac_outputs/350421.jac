"""Replace byte sequences that failed to decode with character escapes.

    Does the same thing as errors="backslashreplace" from Python 3.  Python 2
    lacks this functionality out of the box, so we need to backport it.

    Parameters
    ----------
    ex: UnicodeDecodeError
        contains arguments of the string and start/end indexes of the bad portion.

    Returns
    -------
    text: unicode
        The Unicode string corresponding to the decoding of the bad section.
    end: int
        The index from which to continue decoding.

    Note
    ----
    Works on Py2 only.  Py3 already has backslashreplace built-in.

    """
def _backslashreplace_backport(ex: Any) -> object {
    (bstr, start, end) = (ex.object, ex.start, ex.end);
    text = ''.join('\\x{:02x}'.format(ord(c)) for c in bstr[start:end]);
    return (text, end);
}