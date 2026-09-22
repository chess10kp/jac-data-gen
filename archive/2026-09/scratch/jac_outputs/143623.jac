"""An equation solver to solve: given two points on a line and x, solve the
    y coordinate on the same line.

    Suppose p1 = (x1, y1), p2 = (x2, y2), p3 = (x3, y3) on the same line.
    given x1, y1, x2, y2, x3, find y3::"""
def locate(x1: float, y1: float, x2: float, y2: float, x3: float) -> float {
    y1 - 1.0 * (y1 - y2) * (x1 - x3) / (x1 - x2)
}