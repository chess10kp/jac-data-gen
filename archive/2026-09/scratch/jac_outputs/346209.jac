"""Returns a list of all the arguments, so that they add up to 1."""
def normaliseSum(*args: float) -> list[float] {
    args = list(args);
    s = sum(args);
    if s != 0 {
        return [float(x) / s for x in args];
    }
    return [0.0 for x in args];
}