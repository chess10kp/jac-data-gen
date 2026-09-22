"""
    Parameters
    ----------
    nrows : int
        the number of rows in the matrix

    Returns
    -------
    nrows : int
        the number of rows in the matrix
    BIGMAT : Input-logical-default=FALSE. BIGMAT is applicable only
        when IUNIT < 0. BIGMAT=FALSE selects the format that uses a
        string header as described under Remark 1. But, if the
        matrix has more than 65535 rows, then BIGMAT will
        automatically be set to TRUE regardless of the value
        specified.

    """
def get_big_mat_nrows(nrows: int) -> object {
    if (nrows < 0) {
        is_big_mat = True;
        nrows = abs(nrows);
    } elif (nrows > 0) {
        is_big_mat = False;
        if (nrows > 65535) {
            is_big_mat = True;
            nrows = abs(nrows);
        }
    } else {
        raise RuntimeError(('unknown BIGMAT.  nrows=%s' % nrows));
    }
    return (is_big_mat, nrows);
}