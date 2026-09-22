"""Eqn 1 from Cardelli 1989."""
def extinction_law(a: float, b: float, Rv: float = 3.1) -> float {
    return a + b / Rv;
}