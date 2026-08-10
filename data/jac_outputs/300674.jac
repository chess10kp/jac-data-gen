"""

    Args:
    percentages: output of compute_percentage
    Return: list of strings, the first element should be the best hour,
    the second (and last) element should be the worst hour. Hour are
    represented by string with format %H:%M
    e.g. ["18:00", "20:00"]

    """
def best_and_worst_hour(percentages: Any) -> object {
    hora = 1;
    bestHour = max(zip(percentages.values(), percentages.keys()));
    worstHour = min(zip(percentages.values(), percentages.keys()));
    return [bestHour[hora], worstHour[hora]];
}