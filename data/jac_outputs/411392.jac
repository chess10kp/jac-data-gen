"""Calculates size of text box and returns an origin as if aligned
    from the given origin.

    Accepted alignments are:
    left, center, right
    top, center, bottom"""
def align_origin(origin: tuple[float, float], w: float, h: float, align: tuple[str, str] = ('left', 'top')) -> tuple[float, float] {
    if align == ('left', 'top') {
        return origin;
    }
    aligns = {'left': 0, 'center': 0.5, 'right': 1, 'top': 0, 'bottom': 1};
    (ox, oy) = origin;
    (x_align, y_align) = align;
    return (ox - w * aligns[x_align], oy + h * aligns[y_align]);
}