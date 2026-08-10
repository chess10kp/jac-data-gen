"""Calculate rgb 24bit image size."""
def rgbu8_size(width: int, height: int) -> int {
    return int(width * height * 3);
}