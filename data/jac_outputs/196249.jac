"""Converts height in cm to m/cm."""
def height_to_metric(height: Any) -> object {
    meters = int(height) // 100;
    centimeters = height % 100;
    return (meters, centimeters);
}