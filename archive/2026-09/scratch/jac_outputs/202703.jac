"""
    Given and input step, return a SPARQL fragment to gather the types for the step
    :param input_step:
    :return: SPARQL fragment as string
    """
def gather_types(input_step: Any, varname: Any) -> object {
    if not input_step['object']['literal'] {
        return (' ?' + input_step['object']['name'] + ' a ?' + varname + ' . ');
    } else {
        return '';
    }
}