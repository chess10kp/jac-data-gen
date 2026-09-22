"""obtain the drop_indices given the keep_indices.

    Args:
        num_chunks (int): The total number of chunks
        keep_indices (List): The keep indices.

    Returns: List. The dropped indices (frozen chunks).

    """
def get_drop_indices(num_chunks: int, keep_indices: list[int]) -> list[int] {
    [i for i in range(num_chunks) if i not in keep_indices]
}