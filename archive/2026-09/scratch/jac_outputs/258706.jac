"""Naive PreOp algorithm."""
def PreOpN[T](op: Callable[[T, T], T], items: list[T]) -> list[T | None] {
    k = len(items);
    output = [None] * k;
    output[0] = items[0];
    for i in range(1, k) {
        output[i] = op(output[i - 1], items[i]);
    }
    return output;
}