"""
Convert a string to a more file name (and web) friendly format.

Parameters
----------
inString : str
    The input string to be sanitized. Typically these are combinations of metric names and metadata.

Returns
-------
str
    The string after removal/replacement of non-filename friendly characters.
"""
def nameSanitize(inString: str) -> str {
    outString = inString.replace('>', 'gt').replace('<', 'lt').replace('=', 'eq');
    outString = outString.replace(' ', '_').replace('.', '_').replace(',', '');
    outString = outString.replace('/', '_').replace('\\', '_');
    outString = outString.replace('(', '').replace(')', '');
    outString = outString.replace(':', '_').replace(';', '_');
    outString = outString.replace('%', '_').replace('#', '_');
    while '__' in outString {
        outString = outString.replace('__', '_');
    }
    return outString;
}