"""A range function, that does accept float increments..."""
def frange(start: float, end: float | None = None, inc: float | None = None) -> list[float] {
    if end == None {
        end = start + 0.0;
        start = 0.0;
    }
    if inc == None {
        inc = 1.0;
    }
    L = [];
    while 1 {
        next = start + len(L) * inc;
        if inc > 0 and next >= end {
            break;
        } elif inc < 0 and next <= end {
            break;
        }
        L.append(next);
    }
    return L;
}