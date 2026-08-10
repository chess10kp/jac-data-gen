"""Helper function to convert float format GPS to format used in EXIF."""
def _convert_from_degrees(value: float) -> tuple[int, int, float] {
    degrees = int(value);
    temp = value - degrees;
    temp = temp * 3600;
    minutes = int(temp / 60);
    seconds = temp - minutes * 60;
    return (degrees, minutes, seconds);
}