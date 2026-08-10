"""Linear regression returning [slope, intercept]."""
def estimate_coef(clear_x: list[float], clear_y: list[float]) -> list[float] {
    try {
        n = len(clear_x);
        mean_x = sum(clear_x) / n;
        mean_y = sum(clear_y) / n;
        SS_xy = 0.0;
        SS_xx = 0.0;
        for (index, item) in enumerate(clear_x) {
            SS_xx += item ** 2;
            SS_xy += item * clear_y[index];
        }
        SS_xx -= n * mean_x ** 2;
        SS_xy -= n * mean_x * mean_y;
        B1 = SS_xy / SS_xx;
        B0 = mean_y - B1 * mean_x;
        return [B1, B0];
    } except (TypeError, ZeroDivisionError, OverflowError, ValueError) {
        return [0, 0];
    }
}