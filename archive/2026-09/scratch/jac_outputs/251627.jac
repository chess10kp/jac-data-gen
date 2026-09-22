"""Performs an intrinsic evaluation of a Complex Word Identification approach."""
def evaluateIdentifier(gold: list[int], pred: list[int]) -> tuple[float, float, float] {
    precisionc = 0;
    precisiont = 0;
    recallc = 0;
    recallt = 0;
    for (i, gold_label) in enumerate(gold) {
        predicted_label = pred[i];
        if gold_label == predicted_label {
            precisionc += 1;
            if gold_label == 1 {
                recallc += 1;
            }
        }
        if gold_label == 1 {
            recallt += 1;
        }
        precisiont += 1;
    }
    precision = float(precisionc) / float(precisiont);
    recall = float(recallc) / float(recallt);
    if precision == 0.0 and recall == 0.0 {
        fmean = 0.0;
    } else {
        fmean = 2 * precision * recall / (precision + recall);
    }
    return (precision, recall, fmean);
}