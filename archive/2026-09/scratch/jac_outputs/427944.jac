"""Convert string of floats into sorted list of floats.

    This function will first remove the "TSH" and turn the string of
    floats into the list of floats and sort them from smaller to larger.

    Args:
        float_string (str): A string begin with "TSH" and followed by
            a sequence of floats.

    Returns:
        list: a list of pure sorted floats.
    """
def to_sorted_subfloats(float_string: Any) -> object {
    float_list = float_string.split(",");
    float_list.remove("TSH");
    float_list = [float(i) for i in float_list];
    float_list.sort();
    return float_list;
}