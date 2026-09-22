"""
Calculates cubic function a*x^3+b*x^2+c*x+d
"""
def cubic(x: float, a: float, b: float, c: float, d: float) -> float {
    return a * (x ** 3) + b * (x ** 2) + c * x + d;
}