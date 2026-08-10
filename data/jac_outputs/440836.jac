"""Returns the morphology name from finals.json used in model fitting.

    Args:
        optimized_params_dict (dict): contains the optimized parameters,
            as well as the original morphology path
        emodel (str): name of the emodel

    Returns:
        str: the original morphology name used in model fitting
    """
def morphology_used_in_fitting(optimized_params_dict: dict[str, dict[str, str]], emodel: str) -> str {
    emodel_params = optimized_params_dict[emodel];
    morph_path = emodel_params["morph_path"];
    return morph_path.split("/")[-1];
}