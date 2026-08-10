"""Shift x position slightly."""
def xshift(x: int | float, num: int | float) -> float {
    return x + num * (x * 0.1);
}