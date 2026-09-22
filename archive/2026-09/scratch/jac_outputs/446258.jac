"""Return the lower of the previous low and the new temperature."""
def lower(low: int, temp: int) -> int {
    if temp < low {
        return temp;
    }
    return low;
}