"""Verifies nature of prediction and target given a result_type."""
def result_type_match(pred: int, target: int, result_type: str) -> bool {
    match result_type {
        case 'T':
            return pred == target;
        case 'F':
            return pred != target;
        case 'TP':
            return pred == target and target == 1;
        case 'FP':
            return pred != target and target == 0;
        case 'TN':
            return pred == target and target == 0;
        case 'FN':
            return pred != target and target == 1;
        case _:
            return False;
    }
}