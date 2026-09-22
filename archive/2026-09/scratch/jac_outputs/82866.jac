"""Conversion from rgba to ycc.

    Notes:
         Expects and returns values in [0,255] range.
    """
def _ycc(r: Any, g: Any, b: Any, a: Any = None) -> object {
    y = (0.299 * r) + (0.587 * g) + (0.114 * b);
    cb = (128 - (0.168736 * r) - (0.331364 * g)) + (0.5 * b);
    cr = (128 + (0.5 * r)) - (0.418688 * g) - (0.081312 * b);
    if (a is not None) {
        return [y, cb, cr, a];
    } else {
        return [y, cb, cr];
    }
}