"""Gaussian kernel."""
def gaussian(epsilon: float, obs_data: float, sim_data: float) -> float {
    -0.5 * ((obs_data - sim_data) / epsilon) ** 2
}