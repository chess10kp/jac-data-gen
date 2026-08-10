"""Return the block index for the byte at index i."""
def ith_byte_block(block_size: int, i: int) -> int {
    assert block_size > 0;
    assert i >= 0;
    return i // block_size;
}