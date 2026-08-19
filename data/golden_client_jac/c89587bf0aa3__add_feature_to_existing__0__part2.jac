def:pub apply(func: Callable[[int, int], int], x: int, y: int) -> int {
    return func(x, y);
}

# New: apply a unary function to a single value
def:pub apply_unary(func: Callable[[int], int], x: int) -> int {
    return func(x);
}

with entry {
    add = lambda a: int, b: int : a + b;
    square = lambda n: int : n * n;
    print(apply(add, 3, 4));
    print(apply_unary(square, 5));
}
