import warnings;

"""::deprecated:: 5.9

    Cinema import capabilities are no longer supported in this version.
    """
def ImportCinema(filename: str, view: object | None = None) -> bool {
    warnings.warn("'ImportCinema' is no longer supported", DeprecationWarning);
    return False;
}