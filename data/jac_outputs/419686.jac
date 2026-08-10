"""Format the name of an EWMA metric."""
def make_ewma_metric(metric: str, alpha: int | float) -> str {
    return f"{metric}-ewma-alpha{alpha}";
}