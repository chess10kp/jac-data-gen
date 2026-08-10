"""Test whether two value ranges overlap."""
def overlap(a1: int | None, a2: int | None, b1: int | None, b2: int | None) -> bool {
    if a2 {
        if b1 {
            if b1 >= a2 {
                return False;
            } elif b2 and a1 {
                if a1 > a2 {
                    raise ValueError("Range 1 ends before it started.");
                }
                return b2 > a1;
            } else {
                return True;
            }
        } elif b2 and a1 {
            return b2 >= a1;
        } else {
            return True;
        }
    } elif b2 {
        if a1 {
            return b2 > a1;
        } else {
            return True;
        }
    }
    return True;
}