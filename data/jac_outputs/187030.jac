""" Returns a pattern for a cache file from a certain row

    This function is useful for finding all cache files from a line, ignoring
    the number of images in the file.

    Args:
        row (int): line of the dataset for output
        nbands (int): number of bands in dataset
        regex (bool, optional): return a regular expression instead of glob
            style (default: False)

    Returns:
        str: filename pattern for cache files from line ``row``

    """
def get_line_cache_pattern(row: Any, nbands: Any, regex: Any = False) -> object {
    wildcard = '.*' if regex else '*';
    pattern = 'yatsm_r{l}_n{w}_b{b}.npy.npz'.format(l=row, w=wildcard, b=nbands);
    return pattern;
}