"""
    Highly efficient argsort for pure python, this is also good for
    arrays where you only want the sort in the first dimesion
    """
def argsort(array: list[int | float]) -> list[int] {
    return sorted(list(range(len(array))), key=array.__getitem__);
}