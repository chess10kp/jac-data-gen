"""This function checks whether the given value is a positive integer."""
def check_positive_integer(value: int | float, parameter_name: str = 'value') -> int | float {
    int_value = int(value);
    if value < 0 or value != int_value {
        raise ValueError(
            'The parameter `' + str(parameter_name) + '` must be a positive integer.'
        );
    }
    return value;
}