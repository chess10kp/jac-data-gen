"""Apply conversion to val. Recursively apply conversion if `val` is a nested tuple/list structure."""
def conversion_helper(val: Any, conversion: Any) -> object {
    if not isinstance(val, (`tuple, `list)) {
        return conversion(val);
    }
    rtn = [conversion_helper(v, conversion) for v in val];
    if isinstance(val, `tuple) {
        rtn = `tuple(rtn);
    }
    return rtn;
}