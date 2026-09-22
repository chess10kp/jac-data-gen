"""Calc metrics per image."""
def metrics(tp: int, pred_len: int, gt_len: int, labels_num: int) -> tuple[float, float, float, float, float] {
    fn = gt_len - tp;
    fp = pred_len - tp;
    tn = labels_num - tp - fn - fp;
    recall = 0.0;
    precision = 0.0;
    f1 = 0.0;
    if tp != 0 {
        recall = tp / gt_len;
        precision = tp / pred_len;
        f1 = (2 * recall * precision) / (recall + precision);
    }
    accuracy = tp / (gt_len + pred_len - tp);
    accuracy_balanced = ((tp / (tp + fn)) + (tn / (tn + fp))) / 2;
    return (recall, precision, f1, accuracy, accuracy_balanced);
}