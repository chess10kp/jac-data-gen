"""
Brief:
    return the max value in a list
Arg:
    a list of numeric values, else it will raise an Error
Return:
    the max value
Raise:
    ValueError if value is found
    ValueError if input tab is not a list
"""
def max_value(input_list: list[int | float]) -> int | float {
    if not isinstance(input_list, list) {
        raise ValueError("Expected a list as input");
    }
    if len(input_list) == 0 {
        raise ValueError('provided list is empty');
    }
    max_val = input_list[0];
    for item in input_list {
        if max_val < item {
            max_val = item;
        }
    }
    return max_val;
}