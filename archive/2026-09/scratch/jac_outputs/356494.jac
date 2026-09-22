"""
    Extracts information about a LinkedIn user's undergraduate school

    Parameters
    ----------
    school: the undergraduate school
    undergrad: a list of other undergraduate schools

    Returns
    -------
    The updated list of undergraduate schools and the undergraduate year of graduation
    """
def extract_undergrad(school: Any, undergrad: Any) -> object {
    undergrad.append(school['name']);
    date_range = school['date_range'];
    if (date_range is None) {
        undergrad_yr = 'N/A';
    } elif ('Present' not in date_range) {
        undergrad_yr = int(date_range[-4:]);
    } elif date_range[0:4].isnumeric() {
        undergrad_yr = int(date_range[0:4]) + 4;
    } else {
        undergrad_yr = int(date_range[4:8]);
    }
    return (undergrad, undergrad_yr);
}