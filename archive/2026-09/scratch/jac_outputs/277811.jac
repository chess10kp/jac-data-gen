"""
    Takes list of parameter and returns a string with ', ' between parameters
    :param parameters: list
    :return: parameters concatenated by a semicolon
    :rtype: string
    """
def _join_parameters(parameters: Any) -> object {
    parameter_string = '';
    for p in parameters {
        if (p != '') {
            parameter_string += ', ' + p;
        }
    }
    parameter_string = parameter_string[2:];
    return parameter_string;
}