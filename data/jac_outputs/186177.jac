"""Get drop connect rate for the ith block."""
def get_drop_connect_rate(init_rate: float | None, block_num: int, total_blocks: int) -> float | None {
    if init_rate is not None {
        return (init_rate * float(block_num)) / total_blocks;
    }
    return None;
}