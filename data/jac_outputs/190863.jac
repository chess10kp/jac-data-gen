"""
Convert each RGB tuple of a pixel matrix into a brightness number matrix.

There are numerous ways to convert RGB to brightness, all generating a
slightly different style of transformed image. Here are 3 examples:
Average (average the R, G and B values):
    -> (R + G + B) / 3
Lightness (average the maximum and minimum values out of R, G and B):
    -> max(R, G, B) + min(R, G, B) / 2
Luminosity (take weighted average of RGB to account for human perception):
    ->  0.2126 * R + 0.7152 * G + 0.0722 * B

More information can be found here:
https://stackoverflow.com/questions/596216/formula-to-determine-brightness-of-rgb-color
"""
def get_pixel_brightness_matrix(pixel_matrix: list[list[tuple[int, int, int]]]) -> list[list[float]] {
    def get_pixel_brightness(rgb_tuple: tuple[int, int, int]) -> float {
        (r, g, b) = rgb_tuple;
        0.2126 * r + 0.7152 * g + 0.0722 * b
    }
    [list(map(get_pixel_brightness, row)) for row in pixel_matrix]
}