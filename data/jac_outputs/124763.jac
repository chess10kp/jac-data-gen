"""
    Highlight positive values in red.

    Parameters
    ----------
    test_result : bool
        Observed test result

    Returns
    -------
    str
        Cell background color definition
    """
def highlight_positives(test_result: bool) -> str {
    color = "red" if test_result else "white";
    return f"background-color: {color}";
}