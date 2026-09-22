"""Compute numpy array shape for a given image.

    The output image shape is 2-dim for grayscale, and 3-dim for color images:

    * ``shape = (height, width)`` for FITS images with one grayscale channel
    * ``shape = (height, width, 3)`` for JPG images with three RGB channels
    * ``shape = (height, width, 4)`` for PNG images with four RGBA channels

    Parameters
    ----------
    width, height : int
        Width and height of the image
    fmt : {'fits', 'jpg', 'png'}
        Image format

    Returns
    -------
    shape : tuple
        Numpy array shape
    """
def compute_image_shape(width: int, height: int, fmt: str) -> tuple[int, int] | tuple[int, int, int] {
    if fmt == 'fits' {
        return (height, width);
    } elif fmt == 'jpg' {
        return (height, width, 3);
    } elif fmt == 'png' {
        return (height, width, 4);
    } else {
        raise ValueError(f'Invalid format: {fmt}');
    }
}