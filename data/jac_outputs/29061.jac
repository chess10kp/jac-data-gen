"""
    Returns guess values for the parameters of this function class based on the input. Used for fitting using this
    class.
    """
def guess(key: list[float], values: list[float]) -> list[float] {
    return [max(values) - min(values), 0.5 * (max(key) - min(key)), min(values)];
}