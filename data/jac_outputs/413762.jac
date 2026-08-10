"""Map from `feature` to 0 and `sample` to 1 (for appropriate shape indexing).

    Parameters
    ----------
    space : str, values=('feature', 'sample')
        Feature or sample space.

    Returns
    -------
    return : int, values=(0, 1)
        Index location of the desired space.
    """
def _convert_space_to_shape_index(space: str) -> int | None {
    if space == 'feature' {
        return 1;
    }
    if space == 'sample' {
        return 0;
    }
}