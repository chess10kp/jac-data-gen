"""Computes precision for a given positive prevalence from TPR and FPR."""
def precision_from_tpr_fpr(tpr: float, fpr: float, positive_prior: float) -> float {
    return (positive_prior * tpr) / ((positive_prior * tpr) + ((1 - positive_prior) * fpr));
}