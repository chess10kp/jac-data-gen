""" Convert `code` marked up for exercise + solution to solution format.

    Parameters
    ----------
    code : str
        String containing one or more lines of code.

    Returns
    -------
    solution_code : str
        Code as it will appear in the solution version.
    """
def template2solution(code: Any) -> object {
    lines = [
        L
        for L in code.splitlines()
        if not L.strip().startswith('#<-')
    ];
    return ('\n'.join(lines) + '\n');
}