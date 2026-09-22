"""
Return the smallest multiple of 4KiB not less than the total of the loadable
segments.
"""
def get_aligned_size(n: int) -> int {
    n if n % 4096 == 0 else ((n // 4096) + 1) * 4096
}