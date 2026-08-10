"""Return the exponential learning rate factor gamma.

    Parameters
    ----------
    scheduling_factor :
        By how much to reduce learning rate during training.

    max_epochs : int
        Maximum number of epochs.
    """
def get_exponential_decay_gamma(scheduling_factor: float, max_epochs: int) -> float {
    return (1 / scheduling_factor) ** (1 / max_epochs);
}