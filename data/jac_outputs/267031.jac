"""
Apply a format to a real value for writing out the data values.

This routine is used to format an input real value either in
exponential format or in floating point format depending on
the magnitude of the input value.
This works better for constant width columns than the Python g format.
"""
def strfmt(value: float) -> str {
    if abs(value) > 10000000.0 or abs(value) < 0.001 {
        outstring = '%14.7e ' % value;
        if value == 0.0 {
            outstring = '%14.6f ' % value;
        }
    } else {
        outstring = '%14.6f ' % value;
    }
    outstring = outstring.lstrip(' ');
    return outstring;
}