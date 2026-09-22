"""#3-point function to calaculate 1st derivative"""
def three_point_derivative(f: Callable[[float], float], x: float | int, h: float | int) -> float {
    h = float(h);
    return (1 / (2 * h)) * (f(x - 2 * h) - 4 * f(x - h) + 3 * f(x));
}