"""Convert bytes to MB with 2 decimals"""
def to_mb(val: int | float, update_interval: float | None = None) -> str {
    tmp = 1.0;
    if update_interval {
        tmp = 1 / update_interval;
    }
    return "{:0.2f}".format((val / 1024 / 1024) * tmp);
}