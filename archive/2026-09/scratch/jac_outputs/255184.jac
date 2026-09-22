"""
    :param rate: daily rate
    :param timestep: timesteps per day
    :return: rate rescaled by time step
    """
def discrete_time_approx(rate: float, timestep: float) -> float {
    return 1.0 - (1.0 - rate) ** (1.0 / timestep);
}