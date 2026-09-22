"""
    Helper function to create a dictionary with the given
    demag tolerances and maximum iterations. This can be
    directly passed to the Demag class in order to set
    these parameters.
    """
def create_demag_params(atol: Any, rtol: Any, maxiter: Any) -> object {
    demag_params = {
        'absolute_tolerance': atol,
        'relative_tolerance': rtol,
        'maximum_iterations': int(maxiter)
    };
    return {'phi_1': demag_params, 'phi_2': demag_params};
}