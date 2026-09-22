""" Takes a shape and redraws it in a different bigger scale.
    The positions are offseted but the colors are preserved.

    For simplicity the algorithm first rescales Ys then Xs.
    Each rescale uses anchor to calculate the position of new/old cells.
    The further away we are from the anchor the bigger the offset needs to be
    since we already added (scale-1) number of extra cells up to that point.

    The algorithm is new_pos = pos + (scale-1) * (pos - anchor) + 0:scale

    >>> redraw_in_scale([(0, 0, 5), (0, 1, 9)], 2)
    [(0, 0, 5), (0, 1, 5), (1, 0, 5), (1, 1, 5), (0, 2, 9), (0, 3, 9), (1, 2, 9), (1, 3, 9)]
    """
def redraw_in_scale(shape: Any, scale: Any) -> object {
    temp_new_shape = [];
    (anchor_y, _, _) = min(shape, key=lambda (c: Any) { c[0]; });
    for cell in shape {
        (y, x, colour) = cell;
        for s in range(scale) {
            new_y = y + ((scale - 1) * (y - anchor_y)) + s;
            temp_new_shape.append((new_y, x, colour));
        }
    }
    new_shape = [];
    (_, anchor_x, _) = min(temp_new_shape, key=lambda (c: Any) { c[1]; });
    for cell in temp_new_shape {
        (y, x, colour) = cell;
        for s in range(scale) {
            new_x = x + ((scale - 1) * (x - anchor_x)) + s;
            new_shape.append((y, new_x, colour));
        }
    }
    return new_shape;
}