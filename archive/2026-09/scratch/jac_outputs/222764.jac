"""
    Convert mean/dispersion parameterization of a negative binomial to the ones numpy supports

    See https://en.wikipedia.org/wiki/Negative_binomial_distribution#Alternative_formulations
    From https://stackoverflow.com/a/47406400/2966723
    """
def convert_R_to_numpy_params(mu: float, theta: float) -> tuple[float, float] {
    r = theta;
    var = mu + (1 / r) * (mu ** 2);
    p = (var - mu) / var;
    return (r, (1 - p));
}