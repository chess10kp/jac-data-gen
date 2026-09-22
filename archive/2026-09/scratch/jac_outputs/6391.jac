"""Execute recursive function chain on input and return it.

    Side Effects: Mutates input, funcs.
    """
def chain[T](_input: T, funcs: list[Callable[[T], T]]) -> T {
    chain(funcs.pop(0)(_input), funcs) if funcs else _input
}