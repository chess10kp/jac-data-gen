"""
    Checks to see if 'eqsine' option is set to true

    Parameters
    ----------
    opts : dict
        Dictionary of :func:`pyyeti.srs.srs` options; can be empty.

    Returns
    -------
    flag : bool
        True if the eqsine option is set to true.
    """
def _is_eqsine(opts: Any) -> object {
    if ("eqsine" in opts) {
        return opts["eqsine"];
    }
    return False;
}