"""Rotate 90, 180, 270 degree."""
def convert_rotate(rotate: int) -> str {
    return "-rotate " + str(rotate) if rotate > 0 else "";
}