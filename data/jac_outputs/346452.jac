glob UINT8_MASK = 255;

"""Convert an integer in BGR format to an ``(r, g, b)`` tuple.

    ``bgr_int`` is an integer representation of an RGB color, where the R, G,
    and B values are in the range (0, 255), and the three channels are comined
    into ``bgr_int`` by a bitwise ``red | (green << 8) | (blue << 16)``. This
    leaves the red channel in the least-significant bits, making a direct
    translation to a QColor difficult (the QColor constructor accepts an
    integer form, but it assumes the *blue* channel is in the least-significant
    bits).

    Examples:

        >>> bgr_int_to_rgb(4227327)
        (255, 128, 64)

    """
def bgr_int_to_rgb(bgr_int: int) -> tuple[int, int, int] {
    (red, green, blue) = (
        bgr_int & UINT8_MASK,
        (bgr_int >> 8) & UINT8_MASK,
        (bgr_int >> 16) & UINT8_MASK
    );
    return (red, green, blue);
}