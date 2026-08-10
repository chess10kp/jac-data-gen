""" Create a string representation of a numpy array with less precision
    than the default.

    Parameters
    ----------
    arr : array
        Array to be converted to a string

    precision : int
        Number of significant digit to display each value.

    Returns
    -------
    str
        Nice string representation of the array.
    """
def format_array(arr: Any, precision: Any = 4) -> object {
    if (arr is None) {
        return "";
    }
    formatting_str = "{0:." + str(precision) + "g}";
    str_values = [formatting_str.format(float(val)) for val in arr];
    content = ", ".join(str_values);
    return ("[" + content + "]");
}