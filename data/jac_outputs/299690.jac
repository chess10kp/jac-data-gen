"""
Sticks the given `box`, which is a `(l, t, w, h)`-tuple to the given bounds
which are also expressed as `(l, t, w, h)`-tuple.
"""
def stick_to_bounds(
    box: tuple[int, int, int, int],
    bounds: tuple[int, int, int, int] | None = (0, 0, 1, 1)
) -> tuple[int, int, int, int] {
    if bounds is None {
        return box;
    }
    (l, t, w, h) = box;
    (bl, bt, bw, bh) = bounds;
    l += max(bl - l, 0);
    l -= max((l + w) - (bl + bw), 0);
    t += max(bt - t, 0);
    t -= max((t + h) - (bt + bh), 0);
    return (l, t, w, h);
}