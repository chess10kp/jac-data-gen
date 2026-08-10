"""Returns a sublist with the top k elements from a givenlist. Accepts key"""
def topk(l: list[int | float | str], k: int, key: Callable[[int | float | str], int | float | str] = lambda (x: int | float | str) { x; }) -> list[int | float | str] {
    (idx, _) = zip(
        *sorted(enumerate(l), key=lambda (x: tuple[int, int | float | str]) { key(x[1]); }, reverse=True)
    );
    return [l[i] for i in idx[0:k]];
}