"""
    Convenience function to parse a string into a list using two or more spaces
    as the delimiter.

    Parameters
    ----------
    text : string
        Contains text to be parsed

    Returns
    -------
    textout : list
        list of strings containing the parsed input text
    """
def split(text: Any) -> object {
    textout = [
        s.strip()
        for s in text.split('  ')
        if s.strip()
    ];
    return textout;
}