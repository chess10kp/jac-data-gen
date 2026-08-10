"""
    We have alot of images that have small steering angles.
    This function drops angles that are low with a higher percentage,
    so we have more images with higher angles to train on
    """
def _drop_image_percentage(angle: int | float) -> float {
    absangle = float(abs(angle));
    percentage = 0.5 - (0.05 * absangle);
    return max(0.0, percentage);
}