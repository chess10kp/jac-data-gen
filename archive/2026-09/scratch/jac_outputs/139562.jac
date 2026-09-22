"""
    Get a number in a unified format as label for the hdf5 file.
    """
def get_parameter_label(parameter: Any) -> object {
    return "{:.5f}".format(parameter);
}