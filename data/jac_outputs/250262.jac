"""
Calculate beta, a substitution term based on diffusivity, the spacing
of nodes within the modeled grain, and the timestep. After Ketcham, 2005.
"""
def calculate_beta(diffusivity: float, node_spacing: float, time_interval: float) -> float {
    return (2 * (node_spacing ** 2)) / (diffusivity * time_interval);
}