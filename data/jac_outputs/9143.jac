"""Pythagorean Distance Equation.
    Function for counting distance,
    derived from the Pythagorean theorem.
    """
def pythagorean_distance_equation(path1: list[float], path2: list[float]) -> float {
    x1 = path1[0];
    x2 = path2[0];
    y1 = path1[1];
    y2 = path2[1];
    return ((x2 - x1) ** 2 + (y2 - y1) ** 2) ** 0.5;
}