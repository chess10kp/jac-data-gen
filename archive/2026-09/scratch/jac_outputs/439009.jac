"""

    Args:
        asins ([list]):
        predicted_asins ([list]):
    """
def recall_at_n(asins: list, predicted_asins: list) -> float {
    set_actual = set(asins);
    set_preds = set(predicted_asins);
    num_relevant = len(set_actual.intersection(set_preds));
    recall_at_n = num_relevant / len(asins);
    return recall_at_n;
}