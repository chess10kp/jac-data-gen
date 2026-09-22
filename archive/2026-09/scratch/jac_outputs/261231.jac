"""A fit function to use for fitting IRASA separated 1/f power spectra components."""
def fit_func(freqs: float | list[float], intercept: float, slope: float) -> float | list[float] {
    return slope * freqs + intercept;
}