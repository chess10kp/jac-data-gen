"""Get the forecasted float from xml section."""
def __get_float(section: dict[str, str], name: str) -> float {
    try {
        return float(section[name]);
    } except (ValueError, TypeError, KeyError) {
        return float(0);
    }
}