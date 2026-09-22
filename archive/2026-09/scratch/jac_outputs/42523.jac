"""
Return quadruple (4-tuple) result of quaternion conjugation.
Quaternions are sequences of the form [w, x, y, z].
"""
def qconj(q: list[float] | tuple[float, float, float, float]) -> tuple[float, float, float, float] {
    return tuple(-e if i > 0 else e for (i, e) in enumerate(q));
}