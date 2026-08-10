"""
    Generic percent formatter, just adds a percent sign
    """
def percentformat(x: float, pos: int) -> str {
    if x == 0 {
        return "0%";
    }
    if x < 0.1 {
        return (('%4.3f' % x) + "%");
    }
    if x < 1 {
        return (('%3.2f' % x) + "%");
    }
    if x < 5 {
        return (('%2.1f' % x) + "%");
    }
    return (('%1.0f' % x) + "%");
}