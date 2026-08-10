"""
  Calculate the square of the distance between two coordinates.
  Returns a float
  """
def distx2(x1: list[float], x2: list[float]) -> float {
    return (x1[0] - x2[0]) ** 2 + (x1[1] - x2[1]) ** 2 + (x1[2] - x2[2]) ** 2;
}