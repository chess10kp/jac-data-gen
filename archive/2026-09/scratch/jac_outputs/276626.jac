"""Return value of bits [<start>:<end>] of <n>"""
def get_bits(n: int, start: int, end: int) -> int {
    return (int(n) & ((1 << end) - 1)) >> start;
}