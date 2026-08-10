"""
    Check that the type of value is the Python equivalent of var_type or a list
    of it

    @param var_type (string) Type of val (INTEGER, REAL, LOGICAL, STRING)
    @param val (int/boolean/float/string/list) Value to check

    @return The value in (int, float, boolean, string)
    """
def check_type(var_type: Any, value: Any) -> object {
    res = True;
    if (var_type in ['LOGIQUE', 'LOGICAL']) {
        py_type = bool;
    } elif (var_type in ['ENTIER', 'INTEGER']) {
        py_type = int;
    } elif (var_type in ['REEL', 'REAL']) {
        py_type = float;
    } else {
        py_type = str;
    }
    if isinstance(value, `list) {
        for val in value {
            res = res and isinstance(val, py_type);
        }
    } else {
        res = isinstance(value, py_type);
    }
    return res;
}