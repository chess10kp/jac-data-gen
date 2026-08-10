"""Converts tempint integer to flag.

    Returns:
        Temporal interpolation flag for smooth HDF5 filename
    """
def txx(x: int) -> str {
    if not x {
        return 'n';
    }
    match int(x) {
        case 5:
            return 'p';
        case 10:
            return 'd';
        case _:
            return 'c';
    }
}