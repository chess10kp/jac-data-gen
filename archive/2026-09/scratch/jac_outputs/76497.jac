"""Make the interaction of two sets.

If the original is None, return elements from the new set.
When both operands are None, the result is None.
"""
def _inters(orig: set[int] | None, new: set[int] | None) -> set[int] | None {
    if orig is None {
        return new;
    } elif new is None {
        return orig;
    } else {
        orig &= new;
        return orig;
    }
}