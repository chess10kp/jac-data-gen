"""
Estimates the mass of a lifting surface constructed out of a solid piece of material.
Warning: Not well validated; spar sizing is a guessed scaling and not based on structural analysis.
"""
def mass_surface_solid(
    chord: float, span: float, density: float = 2700, mean_t_over_c: float = 0.08
) -> float {
    mean_t = chord * mean_t_over_c;
    volume = chord * span * mean_t;
    return density * volume;
}