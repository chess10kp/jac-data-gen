"""Integrate one time step with RK4."""
def _rk4_(xy: float, f: Callable[[float, float], float], t: float, dt: float, **kwargs: dict[str, object]) -> float {
    k1 = dt * f(t, xy, **kwargs);
    k2 = dt * f(t + 0.5 * dt, xy + 0.5 * k1, **kwargs);
    k3 = dt * f(t + 0.5 * dt, xy + 0.5 * k2, **kwargs);
    k4 = dt * f(t + 0.5 * dt, xy + 0.5 * k3, **kwargs);
    return xy + (k1 + k2 + k3 + k4) / 6.0;
}