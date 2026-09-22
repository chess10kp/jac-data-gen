"""Assume all questions have at least one answer."""
def computeF1(goldList: list[str], predictedList: list[str]) -> tuple[float, float, float] {
    if len(goldList) == 0 {
        if len(predictedList) == 0 {
            return (1, 1, 1);
        }
        return (0, 0, 0);
    }
    if len(predictedList) == 0 {
        return (0, 1, 0);
    }
    precision = float(sum(1 for entity in predictedList if entity in goldList)) / len(predictedList);
    recall = float(sum(1 for entity in goldList if entity in predictedList)) / len(goldList);
    f1 = 0.0;
    if precision + recall > 0 {
        f1 = (2 * recall * precision) / (precision + recall);
    }
    return (recall, precision, f1);
}