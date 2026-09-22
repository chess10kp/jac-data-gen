"""Strips the extension 'ext' from a file name if it is present, and
    returns the revised name. i.e. fname='datafile.dat', ext='.dat'
    returns 'datafile'.

    See: add_extension

    """
def sub_extension(fname: str, ext: str) -> str {
    if fname.endswith(ext) {
        return fname[:-len(ext)];
    }
    return fname;
}