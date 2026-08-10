"""The closest tuples to tup: decrementing by 1 along any dimension.
Never go into negatives though."""
def decrementAny(tup: tuple[int, ...]) -> list[tuple[int, ...]] {
    res = [];
    for (i, x) in enumerate(tup) {
        if x > 0 {
            res.append(tuple(list(tup[:i]) + [x - 1] + list(tup[i + 1:])));
        }
    }
    return res;
}