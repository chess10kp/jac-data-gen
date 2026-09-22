"""
compute micro FP,FP,FN
"""
def compute_TF_FP_FN_micro(label_dict: dict[str, tuple[float, float, float]]) -> tuple[float, float, float] {
    (TP_micro, FP_micro, FN_micro) = (0.0, 0.0, 0.0);
    for (label, tuplee) in label_dict.items() {
        (TP, FP, FN) = tuplee;
        TP_micro = TP_micro + TP;
        FP_micro = FP_micro + FP;
        FN_micro = FN_micro + FN;
    }
    return (TP_micro, FP_micro, FN_micro);
}