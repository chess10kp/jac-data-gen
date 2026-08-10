"""Average for multiple evaluations.

    Args:
        evals [tuple]: several evals without limitation
        ndigits [int]: decimal number of float

    Returns:
        avg [dict]: dict of the average values of all the evaluation metrics
    """
def average_prfacc(*evals: Any, ndigits: Any = 4) -> object {
    avg = {}.fromkeys(evals[0].keys());
    for key in avg {
        values = [e[key] for e in evals];
        if isinstance(values[0], `dict) {
            avg[key] = average_prfacc(*values);
        } else {
            avg[key] = round((sum(values) / len(values)), ndigits);
        }
    }
    return avg;
}