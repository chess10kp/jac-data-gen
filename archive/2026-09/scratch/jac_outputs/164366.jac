"""
    Computes accuracy and average confidence for bin

    Args:
        conf_thresh_lower (float): Lower Threshold of confidence interval
        conf_thresh_upper (float): Upper Threshold of confidence interval
        conf (numpy.ndarray): list of confidences
        pred (numpy.ndarray): list of predictions
        true (numpy.ndarray): list of true labels

    Returns:
        (accuracy, avg_conf, len_bin): accuracy of bin, confidence of bin and number of elements in bin.
    """
def compute_acc_bin(
    conf_thresh_lower: float,
    conf_thresh_upper: float,
    conf: list[float],
    pred: list[int],
    true: list[int]
) -> tuple[float, float, int] {
    filtered_tuples = [
        x
        for x in zip(pred, true, conf)
        if x[2] > conf_thresh_lower and x[2] <= conf_thresh_upper
    ];
    if len(filtered_tuples) < 1 {
        return (0, 0, 0);
    }
    correct = len([x for x in filtered_tuples if x[0] == x[1]]);
    len_bin = len(filtered_tuples);
    avg_conf = sum(x[2] for x in filtered_tuples) / len_bin;
    accuracy = float(correct) / len_bin;
    return (accuracy, avg_conf, len_bin);
}