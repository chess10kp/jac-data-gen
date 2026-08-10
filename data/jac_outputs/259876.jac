"""
    Calculate a simple score on a scale of 1 to 10 based on the
    given metrics. Each metric is given 2 points. If alpha is zero,
    then the score is zero since you have made no positive returns
    correlation
        correlation of strategy, between 1 and -1
    sharpe
        sharpe ratio
    drawdown
        max drawdown percentage
    alpha
        excess returns
    sensitivity
        price sensitivity based on open=high or open=low prices
    out
        output format.
        returns score if None else the list of points for
        any other argument
    """
def simple_score(
    correlation: float,
    sharpe: float,
    drawdown: float,
    alpha: float,
    sensitivity: float,
    out: str | None = None
) -> list[float] | float | int {
    points: list[float] = [0.0, 0.0, 0.0, 0.0, 0.0];
    correlation = abs(correlation);
    drawdown = abs(drawdown);
    if correlation < 0.1 {
        points[0] = 2.0;
    } else {
        points[0] = 2.0 * (1.0 - correlation);
    }
    if sharpe > 0 {
        points[1] = min(2.0, sharpe);
    }
    if abs(drawdown) < 0.05 {
        points[2] = 2.0;
    } else {
        points[2] = max(0.0, 2.0 - (drawdown - 0.05) * 0.25 * 100.0);
    }
    if alpha > 0 {
        points[3] = min(2.0, alpha * 100.0);
    }
    if sensitivity < 0.1 {
        points[4] = 2.0;
    } else {
        points[4] = max(0.0, (0.3 - sensitivity) * 10.0);
    }
    if out == "list" {
        return points;
    }
    return 0 if alpha <= 0 else sum(points);
}