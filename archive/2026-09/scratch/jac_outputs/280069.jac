"""
    Returns an integer size and scale that best approximates
    the floating point scale on the original size

    Args:
        dsize (tuple): original width height
        scale (float or tuple): desired floating point scale factor
    """
def get_round_scaled_dsize(dsize: tuple[int, int], scale: float | tuple[float, float]) -> tuple[tuple[int, int], tuple[float, float]] {
    try {
        (sx, sy) = scale;
    } except TypeError {
        sx = sy = scale;
    }
    (w, h) = dsize;
    new_w = int(round(w * sx));
    new_h = int(round(h * sy));
    new_scale = (new_w / w, new_h / h);
    new_dsize = (new_w, new_h);
    return (new_dsize, new_scale);
}