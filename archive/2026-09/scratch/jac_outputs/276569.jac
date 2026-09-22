"""Checks, if the region within lp1 and lp2 is structurally balanced"""
def isStructureCompatible(lp1: int, lp2: int, bp: list[int]) -> bool {
    x = lp1 + 1;
    while x < lp2 {
        if bp[x] <= lp1 or bp[x] > lp2 {
            return False;
        }
        if x == bp[x] {
            x += 1;
        } else {
            x = bp[x] + 1;
        }
    }
    return x == lp2;
}