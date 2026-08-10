"""Generate sequence (that unlike xrange supports float).

    max: defines the sequence maximum
    step: defines the interval
    """
def _generate_Sequence(min: int | float, max: int | float, step: int | float) -> list[int | float] {
    i = min;
    seq = [];
    while i <= max {
        seq.append(i);
        i = i + step;
    }
    return seq;
}