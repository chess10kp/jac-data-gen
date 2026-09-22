"""
    This function returns the precision for indels by size.

    :param tp: Number of true positives
    :type tp: int
    :param fp: Number of false positives
    :type fp: int

    :return: The precision, (tp) / (tp+fp)
    :rtype: float
    """
def get_precision(tp: Any, fp: Any) -> object {
    if ((tp + fp) == 0) {
        return 'NaN';
    } else {
        return format(round((100 * (float(tp) / (tp + fp))), 2), '.2f');
    }
}