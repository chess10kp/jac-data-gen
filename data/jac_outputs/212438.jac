"""A naive way to map width to z axis position."""
def naive_width2z(width: float) -> float {
    assert width >= 0;
    return 0.01 - width;
}