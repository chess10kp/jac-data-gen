"""
    Returns the column(s) '*i' of a 2D list 'mat'

    mat: matrix or 2D list
    *i: columns to extract from matrix

    NOTE: If one column is given, the column is returned as a list.
    If multiple columns are given, a list of columns (also lists) is returned
    """
def cget(mat: Any, *i: Any) -> object {
    if (len(i) == 1) {
        return [row[i[0]] for row in mat];
    } else {
        return [[row[index] for row in mat] for index in i];
    }
}