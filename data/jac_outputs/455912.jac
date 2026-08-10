"""
    Return a new parameters dict with the magnet parameters in the form
    '<prefix>_<magnet>_<segment>', with the values from 'magnet_parameters'
    and other parameters from 'params'.

    The length of the array 'magnet_parameters' must be equal to the sum of
    the number of segments in both cylinders.

    The first n_II elements refer to the inner magnet,
    and the remaining elements to the outer magnet.
    """
def expand_parameters_from_remanence_array(
    magnet_parameters: Any, params: Any, prefix: Any
) -> object {
    params_expanded = params.copy();
    n_II = params["n_II"];
    for i in range(0, n_II) {
        params_expanded[("%s_II_%d" % (prefix, (i + 1)))] = magnet_parameters[i];
    }
    n_IV = params["n_IV"];
    for j in range(0, n_IV) {
        k = j + n_II;
        params_expanded[("%s_IV_%d" % (prefix, (j + 1)))] = magnet_parameters[k];
    }
    return params_expanded;
}