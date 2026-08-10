"""Determine if a location is block-aligned."""
def block_aligned(location: int, block_size: int) -> bool {
    return (location & (block_size - 1)) == 0;
}