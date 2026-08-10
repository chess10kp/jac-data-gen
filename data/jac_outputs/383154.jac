"""Returns a permutation to make a (N, ..., C) array into (N, C, ...)."""
def get_channels_first_permutation(spatial: int) -> list[int] {
    return [0, spatial + 1] + list(range(1, spatial + 1));
}