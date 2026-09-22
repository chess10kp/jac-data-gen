"""Combine the image paths from `center`, `left` and `right` using the correction factor `correction`
Returns ([image_paths], [measurements])
"""
def combine_images(
    center: list[str],
    left: list[str],
    right: list[str],
    measurement: list[int | float],
    correction: int | float
) -> tuple[list[str], list[int | float]] {
    image_paths = [];
    image_paths.extend(center);
    image_paths.extend(left);
    image_paths.extend(right);
    measurements = [];
    measurements.extend(measurement);
    measurements.extend([(x + correction) for x in measurement]);
    measurements.extend([(x - correction) for x in measurement]);
    return (image_paths, measurements);
}