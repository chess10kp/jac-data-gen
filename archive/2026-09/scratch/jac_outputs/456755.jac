"""Computes absolute length difference between target and predicted sequences."""
def abs_length_diff(trg: str, pred: str) -> int {
    trg_length = len(trg.split(' '));
    pred_length = len(pred.split(' '));
    return abs(trg_length - pred_length);
}