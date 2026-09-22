"""
    Calculates goodness of fit for the provided values, and scales based on the total number of individuals that exist.
    The calculation is 1 - (abs(x - y)/max(x, y)) * n/n_tot for x, y simulated and actual values, n, n_tot for metric
    and total
    number of individuals.

    :param simulated_value: the simulated value of the metric
    :param actual_value: the actual value of the metric
    :param number_individuals: the number of individuals this metric relates to
    :param total_individuals: the total number of individuals across all sites for this metric
    :return: the scaled fit value
    """
def scale_simulation_fit(
    simulated_value: Any,
    actual_value: Any,
    number_individuals: Any,
    total_individuals: Any
) -> object {
    return (
        (
            (
                1
                - (
                    abs((simulated_value - actual_value))
                    / max(simulated_value, actual_value)
                )
            )
            * number_individuals
        )
        / total_individuals
    );
}