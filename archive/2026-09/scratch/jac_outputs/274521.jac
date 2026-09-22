"""
    This is needed in the find_hexad function below.
    """
def picture_set(A: list[int], L: list[int]) -> set[int] {
    return {A[x] for x in L};
}