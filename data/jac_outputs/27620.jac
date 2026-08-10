"""Scales length l to pixel units, using supplied
       pixel width in arbitrary length units
    """
def to_pixel_units(l: Any, pixelwidth: Any) -> object {
    try {
        return (l / pixelwidth);
    } except (TypeError, ZeroDivisionError) {
        return l;
    }
}