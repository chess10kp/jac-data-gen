"""Get file format by name.

    Parameters
    ----------
    path : str
        Path to file.

    Returns
    -------
    str
        File format as a string.
    """
def _guess_format_from_name(path: Any) -> object {
    import os;
    fname = os.path.basename(path);
    if fname.endswith('.nc') {
        return 'netcdf';
    } elif fname.endswith('.asc') {
        return 'esri-ascii';
    } else {
        return None;
    }
}