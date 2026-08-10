"""Computing the forecast for the drift model

    """
def drift_forecast(submodel: Any, horizon: Any) -> object {
    points = [];
    for h in range(horizon) {
        points.append((submodel["value"] + (submodel["slope"] * (h + 1))));
    }
    return points;
}