glob PRECISION_EPSILON = 1e-09;

"""
    :returns: precision metric for one image at one threshold
    """
def precision(tp: int, fp: int, fn: int) -> float {
    return float(tp) / (tp + fp + fn + PRECISION_EPSILON);
}