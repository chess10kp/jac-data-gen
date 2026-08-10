"""
    Check whether test_value is larger (>) than a certain value
    that is computed as: center + metric * interval_range

    :param float test_value: value to be compared
    :param float metric: value of metric used to comparison (IQR or std)
    :param float center: center of comparison (for example, Q1)
    :param float interval_range: value to multiply metric by
    :return: whether test value is above range
    """
def above_range(
    test_value: float, metric: float, center: float, interval_range: float
) -> bool {
    test_value > center + metric * interval_range
}