"""
    Takes a number and returns a string putting a zero in front if it's
    single digit.
    """
def stringify(num: int) -> str {
    num_string = str(num);
    if len(num_string) == 1 {
        num_string = '0' + num_string;
    }
    return num_string;
}