"""Repeatedly apply a function using a regular python loop."""
def unrolled[T](
    i: int,
    init_x: T,
    func: Callable[[T], T],
    num_iter: int,
    return_last_two: bool = False
) -> tuple[int, T] | tuple[int, T, T | None] {
    x = init_x;
    x_old: T | None = None;
    for _ in range(num_iter) {
        x_old = x;
        x = func(x_old);
        i = i + 1;
    }
    if return_last_two {
        return (i, x, x_old);
    }
    return (i, x);
}