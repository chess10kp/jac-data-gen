"""Punctul apartine imaginii
    """
def inrange(imagine: list[list[int]], punct: tuple[int, int]) -> int {
    (ccx, ccy) = punct;
    length = len(imagine[0]);
    width = len(imagine);
    if ccx < width and ccx > -1 and ccy < length and ccy > -1 {
        return 1;
    }
    return 0;
}