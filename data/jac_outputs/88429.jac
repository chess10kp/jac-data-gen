"""Define region of image to crop."""
def get_crop_range(maxX: int, maxY: int, size: int = 32) -> tuple[int, int, int, int] {
    return (maxX - size, maxX + size, maxY - size, maxY + size);
}