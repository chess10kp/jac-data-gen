"""
Parameters
----------
column : float or tuple
    gives the column or (column, unc) or (column, punc, munc)

Returns
-------
column: float
    column value
"""
def _get_column_val(column: float | tuple[float, ...]) -> float {
    if isinstance(column, tuple) {
        return float(column[0]);
    }
    return float(column);
}