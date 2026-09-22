"""Ensure a channel number is divisible by the given divisor."""
def make_divisible(v: int | float, divisor: int, min_value: int | None = None) -> int {
    if min_value is None {
        min_value = divisor;
    }
    new_v = max(min_value, int(v + divisor / 2) // divisor * divisor);
    if new_v < 0.9 * v {
        new_v += divisor;
    }
    return new_v;
}