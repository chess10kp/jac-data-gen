"""Apply a gamma adjustment to a byte."""
def gammacorrectbyte(lumbyte: int, gamma: float) -> int {
    int(((lumbyte / 255) ** gamma) * 255)
}