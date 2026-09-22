"""
    Return the classical-basis labels based on a vector dimension.
    """
def cl_labels(dim: int) -> list[str] {
    if dim == 0 {
        return [];
    }
    if dim == 1 {
        return [''];
    }
    return [("%d" % i) for i in range(dim)];
}