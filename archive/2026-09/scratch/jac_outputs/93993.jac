"""
    Format prediction probability for displaying
    INPUT
        prob: raw model probability, float
    OUTPUT
        label : cleaned probability, str
    """
def _format_probability(prob: Any) -> object {
    return f'{round((100 * prob), 2)}%';
}