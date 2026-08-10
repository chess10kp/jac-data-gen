"""
    recover "17" to 17.
    recover "[]" to [].
    recover "datetime(2020,1,1)" to datetime(2020,1,1).
    keep "abc" as str.

    :param v: str.
    :return: Any.
    """
def _recover_type(v: Any) -> object {
    try {
        nv = eval(v);
    } except (NameError, SyntaxError) {
        nv = v;
    }
    if callable(nv) {
        nv = v;
    }
    return nv;
}