"""
    Generates a formatted string of the variables to query for
    :param census_vars: a list of variables to join
    :return: a string containing the variables delimited by commas
    """
def get_census_var_string(census_vars: Any) -> object {
    if (len(census_vars) == 1) {
        return census_vars;
    }
    delimiter = ",";
    return delimiter.join(census_vars);
}