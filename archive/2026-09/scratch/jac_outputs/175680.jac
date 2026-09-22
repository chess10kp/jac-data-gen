"""Exponentially decays.

    Args:
        t: Current step, starting from 0
        t0: Decay start
        t1: Decay end
        factor: Decay factor
        eps0: start learning rate
    """
def exponential_decay_fn(t: float, t0: float, t1: float, eps0: float, factor: float) -> float {
    if t < t0 {
        return eps0;
    }
    lr = eps0 * pow(factor, (t - t0) / (t1 - t0));
    return lr;
}