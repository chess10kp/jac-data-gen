"""Elementwise addition of two tuples."""
def tuple_diff(t1: tuple[int, ...], t2: tuple[int, ...]) -> tuple[int, ...] {
    return tuple(t1[i] - t2[i] for i in range(len(t1)));
}