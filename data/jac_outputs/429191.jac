"""
    Given an index ``bin``, the number of the bins ``num_bins``, and the limits
    on a single state dimension, this function returns the corresponding value
    in the middle of the bin (ie, the average of the discretizations around it)

    This is the inverse of state2bin function.
    """
def bin2state(bin: int, num_bins: int, limits: list[float]) -> float {
    bin_width = (limits[1] - limits[0]) / num_bins;
    return (bin * bin_width) + (bin_width / 2) + limits[0];
}