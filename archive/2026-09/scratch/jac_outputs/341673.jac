"""
	Return derivatives for harmonic oscillator:
		y'' = -(k/m) * y
	y = displacement in [m]
	k = spring_constant in [N/m]
	m = mass in [kg]
	"""
def F(y: list[float], t: float, spring_constant: float = 1.0, mass: float = 1.0) -> list[float] {
    dy = [0.0, 0.0];
    dy[0] = y[1];
    dy[1] = -(spring_constant / mass) * y[0];
    return dy;
}