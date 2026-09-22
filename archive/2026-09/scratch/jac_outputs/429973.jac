"""
    reduceWith takes reducer as first argument, computes a reduction over iterable.
    Think foldl from Haskell.
    """
def reduceWith[T, U](reducer: Callable[[U, T], U], seed: U, iterable: list[T]) -> U {
    accumulation = seed;
    for value in iterable {
        accumulation = reducer(accumulation, value);
    }
    return accumulation;
}