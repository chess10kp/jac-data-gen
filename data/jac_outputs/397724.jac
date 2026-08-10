"""Return a zero mat in list format.

    Args:
        n (int, optional):
            Length of the edge.
            Defaults to 3.

    Returns:
        list:
            List[List[int]]
    """
def __zero_mat_list__(n: Any = 3) -> object {
    ret_list = [([0] * n) for _ in range(n)];
    return ret_list;
}