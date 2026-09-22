"""
Calculates magnetar giant flare energy for a given flare interval,
based on the energy injection rate and a flare interval.
"""
def energy_calc(edot: float, t_int: float) -> float {
    return edot * t_int;
}