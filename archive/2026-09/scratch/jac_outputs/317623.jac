"""Implementation of greater than return False if a or b are NoneType values"""
def gt_with_none(a: Any, b: Any) -> object {
    if ((a is None) or (b is None)) {
        return False;
    } else {
        return (a > b);
    }
}