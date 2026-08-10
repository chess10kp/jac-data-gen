"""
    check the overlap of a region for the same chromosome
    """
def checkOneEndOverlap(xa: int, xb: int, ya: int, yb: int) -> bool {
    if ya <= xa <= yb or ya <= xb <= yb or ya <= xa <= xb <= yb {
        return True;
    }
    if xa <= ya <= xb or xa <= yb <= xb or xa <= ya <= yb <= xb {
        return True;
    }
    return False;
}