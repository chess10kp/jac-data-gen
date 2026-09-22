"""
    Calculate the AP given the recall and precision array
    1st) We compute a version of the measured precision/recall curve with
         precision monotonically decreasing
    2nd) We compute the AP as the area under this curve by numerical integration.
    """
def voc_ap(rec: list[float], prec: list[float]) -> float {
    rec.insert(0, 0.0);
    rec.append(1.0);
    mrec = rec[:];
    prec.insert(0, 0.0);
    prec.append(0.0);
    mpre = prec[:];
    for i in range(len(mpre) - 2, -1, -1) {
        mpre[i] = max(mpre[i], mpre[i + 1]);
    }
    i_list = [i for i in range(1, len(mrec)) if mrec[i] != mrec[i - 1]];
    ap = 0.0;
    for i in i_list {
        ap += (mrec[i] - mrec[i - 1]) * mpre[i];
    }
    return ap;
}