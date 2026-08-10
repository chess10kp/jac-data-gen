"""
    Function to calculate the minimum required management strategy for the
    entire program or a test phase.

    :param float fef: the average fix effectiveness factor over the period to
                      calculate the management strategy.
    :param float mtbfa: the average MTBF over the first test phase.
    :param float mtbfgp: the growth protential MTBF.
    :return: _avg_ms
    :rtype: float
    """
def calculate_management_strategy(fef: float, mtbfa: float, mtbfgp: float) -> float {
    try {
        _avg_ms = (1.0 - (mtbfa / mtbfgp)) / fef;
    } except ZeroDivisionError {
        _avg_ms = 1.0;
    }
    return _avg_ms;
}