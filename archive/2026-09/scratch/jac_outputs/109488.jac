"""
    Take a string referring to an age group and find it's upper and lower limits.

    Args:
        age_string: The string to be analysed
    Returns:
        limits: List of the lower and upper limits
        dict_limits: Dictionary of the lower and upper limits
    """
def interrogate_age_string(age_string: Any) -> object {
    assert (age_string[:4] == '_age') , 'Age string does not begin with "_age".';
    ages = age_string[4:];
    lower_age_limit = '';
    for (i, letter) in enumerate(ages) {
        if letter.isdigit() {
            lower_age_limit += letter;
        } else {
            break;
        }
    }
    remaining_string = ages[len(lower_age_limit):];
    if (lower_age_limit != '') {
        lower_age_limit = float(int(lower_age_limit));
    }
    if (remaining_string == 'up') {
        upper_age_limit = float('inf');
    } elif (remaining_string[:2] == 'to') {
        upper_age_limit = float(remaining_string[2:]);
    } else {
        raise NameError('Age string incorrectly specified');
    }
    limits = [lower_age_limit, upper_age_limit];
    dict_limits = {age_string: limits};
    return (limits, dict_limits);
}