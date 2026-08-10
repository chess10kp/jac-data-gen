"""Scale to Home-Assistant value."""
def scaleto255(value: Any) -> object {
    return max(0, min(255, round(((value * 255.0) / 100.0))));
}