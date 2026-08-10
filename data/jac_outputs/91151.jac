"""Convert the list into a list of couples of two elements."""
def in2s(nms: list[int]) -> list[tuple[int, int]] {
    return list(zip(nms[::2], nms[1::2]));
}