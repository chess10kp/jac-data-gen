"""
    >>> parse_file_string("File 123: ABC (X, Y) Z")
    ('ABC (X, Y) Z', '')
    >>> parse_file_string("File 123: ABC (X) Y (Z)")
    ('ABC (X) Y', 'Z')
    >>> parse_file_string("File: ABC")
    ('ABC', '')
    >>> parse_file_string("File 2: A, B, 1-2")
    ('A, B, 1-2', '')
    """
def parse_file_string(filestring: Any) -> object {
    if (filestring.strip()[-1] != ")") {
        filestring = filestring.strip() + "()";
    }
    if (':' in filestring) {
        rhs = filestring.partition(":")[2];
    } else {
        rhs = filestring;
    }
    chunks = rhs.split('(');
    indname = '('.join(chunks[:-1]);
    units = chunks[-1].replace(')', '');
    return (indname.strip(), units.strip());
}