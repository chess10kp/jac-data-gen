"""Dictionaries are more convenient for storing and working with the parameters of the gaussians and lorentzians,
but leastsq wants the initial parameters as a list (as far as I can tell...). This will take a list of dictionaries
and convert it to a single list according to the following order:
yoffset, ymax, halfwidth, x0 (repeating ymax, halfwidth, and x0 for any additional functions)"""
def params_to_lists(params: list[dict[str, float]]) -> list[float] {
    if `type(params) != list {
        raise TypeError(
            'Incorrect data type: function params_to_list needs a list of dictionaries.'
        );
    }
    list_of_params = [params[0]['yoffset']];
    for peak in params {
        list_of_params.append(peak['ymax']);
        list_of_params.append(peak['halfwidth']);
        list_of_params.append(peak['x0']);
    }
    return list_of_params;
}