"""Interpret quantile q input to quantile plot range tuple."""
def quantile_plot_interval(q: str | float | int | tuple[float, float]) -> float | int | tuple[float, float] {
    if isinstance(q, str) {
        sigmas = {
            '1sigma': 0.682689492137086,
            '2sigma': 0.954499736103642,
            '3sigma': 0.99730020393674,
            '4sigma': 0.999936657516334,
            '5sigma': 0.999999426696856
        };
        q = (1 - sigmas[q]) / 2;
    }
    if isinstance(q, float) or isinstance(q, int) {
        if q > 0.5 {
            q = 1 - q;
        }
        q = (q, 1 - q);
    }
    return q;
}