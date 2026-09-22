"""Computes the dim size of the chunk for the given idx, dim_size, and split_size."""
def get_chunked_dim_size(dim_size: int, split_size: int, idx: int) -> int {
    return min(dim_size, split_size * (idx + 1)) - split_size * idx;
}