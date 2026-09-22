"""Calculates the integration time in seconds."""
def calc_t_int(n_group: int, t_frame: float, n_frame: int, n_skip: int) -> float {
    return ((n_group * (n_frame + n_skip)) - n_skip) * t_frame;
}