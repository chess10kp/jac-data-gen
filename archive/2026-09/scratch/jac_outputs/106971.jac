"""Definition of the system of ODE for the Lotka-Volterra system."""
def LotkaVolterra(
    y: tuple[float, float],
    time: float,
    alpha: float,
    beta: float,
    gamma: float,
    delta: float
) -> list[float] {
    (r, f) = y;
    return [alpha * r - beta * f * r, delta * f * r - gamma * f];
}