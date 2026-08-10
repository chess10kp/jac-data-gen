""" This function is auxiliary for the natural sorting of the paths names"""
def atof(text: Any) -> object {
    try {
        retval = float(text);
    } except ValueError {
        retval = text;
    }
    return retval;
}