"""Calculates the Fourier number from thermal diffusion parameters."""
def fourier_number(
    conductive_length_scale: float,
    conductivity: float,
    density: float,
    heat_capacity: float,
    time_scale: float
) -> float {
    (conductivity * time_scale)
        / (heat_capacity * density * (conductive_length_scale ** 2))
}