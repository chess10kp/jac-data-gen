"""
    defines the input to the system
    """
def xd(t: Any, L: Any, StartTime: Any) -> object {
    xd = L * (t >= StartTime);
    return xd;
}