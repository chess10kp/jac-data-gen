"""Check if a variable is an float or a none."""
def checkFloat(value: Any, `default: Any, allowNone: Any = False) -> object {
    if (allowNone and ((value is None) or (value == "None"))) {
        return None;
    }
    try {
        return float(value);
    } except Exception {
        return `default;
    }
}