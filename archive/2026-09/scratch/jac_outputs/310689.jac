"""
    Calculates Unix time for individual sample point (within a record).
    The sample point time is calculated by subtracting a multiple of
    1/sr from the reference time corresponding to the final sample point
    in the record, where sr is the sample rate.
    """
def get_sample_t(ref_t: float, idx: int, num_samples: int, sr: float) -> float {
    return ref_t - (1 / sr) * (num_samples - 1 - idx);
}