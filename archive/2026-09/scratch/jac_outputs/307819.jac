"""Limit value to be between lower and upper limits"""
def clip(val: Any, lower: Any = 0, upper: Any = 100) -> object {
    return max(lower, min(val, upper));
}