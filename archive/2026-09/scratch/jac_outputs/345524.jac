"""
    quick function to tell if a number should be zero but is off
    due to computer error
    """
def almost_zero(number: float) -> bool {
    return abs(number) < 1e-10;
}