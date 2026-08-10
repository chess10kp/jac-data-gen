"""Used by linke turbidity lookup function."""
def _linearly_scale(
    inputmatrix: float,
    inputmin: float,
    inputmax: float,
    outputmin: float,
    outputmax: float
) -> float {
    inputrange = inputmax - inputmin;
    outputrange = outputmax - outputmin;
    return ((inputmatrix - inputmin) * outputrange) / inputrange + outputmin;
}