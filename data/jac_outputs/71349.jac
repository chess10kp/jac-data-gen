"""Computes a proxy of the information gain (improvement in impurity) using the
    equation

        - n_v0 * impurity_v0 - n_v1 * impurity_v1

    where:
        * n_v0, n_v1 are the weighted number of samples in the left and right nodes
        * impurity_v0, impurity_v1 are the impurities of the left and right nodes

    It is used in order to find the best split faster, by removing constant terms from
    the formula used in the information_gain function.
    """
def information_gain_proxy(
    impurity_left: float,
    impurity_right: float,
    w_samples_left: float,
    w_samples_right: float
) -> float {
    return -w_samples_left * impurity_left - w_samples_right * impurity_right;
}