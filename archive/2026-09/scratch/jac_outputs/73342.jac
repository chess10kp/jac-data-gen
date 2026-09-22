"""
    Every condition can hold up to max_conditions, which (as of writing this) is 10.
    Every time a condition is created, (max_conditions) are used and 1 new one is added to the conditions list.
    This means that there is a net decrease of up to (max_conditions-1) with each iteration.

    This formula calculates the number of conditions needed.
    x items in groups of y, where every group adds another number to x
    Math: either math.ceil((x-1)/(y-1))
            or  math.floor((x+(y-1)-2)/(y-1)) == 1 + (x-2)//(y-1)

    :param int conditions_length: total # of conditions to handle
    :param int max_conditions: maximum number of conditions that can be put in an Fn::Or statement
    :return: the number (int) of necessary additional conditions.
    """
def calculate_number_of_conditions(
    conditions_length: Any, max_conditions: Any
) -> object {
    num_conditions = 1 + ((conditions_length - 2) // (max_conditions - 1));
    return num_conditions;
}