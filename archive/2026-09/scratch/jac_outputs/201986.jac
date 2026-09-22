"""Calculate fee based on transaction size and price per KiB."""
def estimate_fee(estimated_size: int, fee_kb: int) -> int {
    return int(estimated_size * fee_kb / 1024.0 + 0.5);
}