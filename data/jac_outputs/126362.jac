"""
    Utility function to be used as input to various SampleAugmenter functions, specifying random parameter points
    sampled from a prior in a morphing setup.

    Parameters
    ----------
    n_thetas : int
        Number of parameter points to be sampled

    priors : list of tuples
        Priors for each parameter is characterized by a tuple of the form `(prior_shape, prior_param_0, prior_param_1)`.
        Currently, the supported prior_shapes are `flat`, in which case the two other parameters are the lower and upper
        bound of the flat prior, and `gaussian`, in which case they are the mean and standard deviation of a Gaussian.

    Returns
    -------
    output : tuple
        Input to various SampleAugmenter functions

    """
def random_morphing_points(
    n_thetas: int,
    priors: list[tuple[str, float, float]]
) -> tuple[str, tuple[int, list[tuple[str, float, float]]]] {
    return ("random_morphing_points", (n_thetas, priors));
}