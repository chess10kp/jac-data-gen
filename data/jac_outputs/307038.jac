"""
    Combine the image paths from `center`, `left` and `right` using the correction factor `correction`
    Returns ([imagePaths], [measurements])
    """
def CombineImages(
    center: list[str],
    left: list[str],
    right: list[str],
    measurement: list[int | float],
    correction: int | float
) -> tuple[list[str], list[int | float]] {
    imagePaths = [];
    imagePaths.extend(center);
    imagePaths.extend(left);
    imagePaths.extend(right);
    measurements = [];
    measurements.extend(measurement);
    measurements.extend([(x + correction) for x in measurement]);
    measurements.extend([(x - correction) for x in measurement]);
    return (imagePaths, measurements);
}