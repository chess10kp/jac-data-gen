"""t^1/2 fit w/ 2 params: slope a and horizontal shift t0."""
def square_root_2param_t0_fit(t: Any, a: Any, t0: Any) -> object {
    return (a * ((t - t0) ** 0.5));
}