"""Obtain rounding value for a float with optional upper boundary."""
def round2int(value: float, boundary: int = -1) -> int {
    if value - int(value) >= 0.5 {
        if boundary == -1 or int(value) + 1 <= boundary {
            return int(value) + 1;
        }
        return boundary;
    }
    return int(value);
}