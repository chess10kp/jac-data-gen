"""Copies param_dict so as not to modify user's dictionary. Then reformats out_species from pythonic list
    to a string of space separated names for Fortran.
    """
def _reform_inputs(param_dict: Any, out_species: Any) -> object {
    if (param_dict is None) {
        param_dict = {};
    } else {
        param_dict = {k.lower(): v for (k, v) in param_dict.items()};
    }
    if (out_species is not None) {
        n_out = len(out_species);
        param_dict["outspecies"] = n_out;
        out_species = " ".join(out_species);
    } else {
        out_species = "";
        n_out = 0;
    }
    return (n_out, param_dict, out_species);
}