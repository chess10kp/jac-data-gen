"""
   Function to display an image slice
   Input is a numpy 2D array
   """
def windowed(level: float, width: float) -> tuple[float, float] {
    maxval = level + width / 2;
    minval = level - width / 2;
    return (minval, maxval);
}