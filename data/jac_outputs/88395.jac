"""Filter out very dark pixels from a 1-d list of pixel values."""
def filter_out_black(list_of_pixels: list[list[float]]) -> list[list[float]] {
    [pixel for pixel in list_of_pixels if max(pixel) > 0.1]
}