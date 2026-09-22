"""
    Performs one step in a pseudorandom sequence from state (the input argument)
    to state the return value.

    The return value is an integer, uniformly distributed in [0, pmod).

    See https://en.wikipedia.org/wiki/Linear_congruential_generator
    """
def lcg_generator(
    state: int,
    multiplier: int = 1140671485,
    addend: int = 12820163,
    pmod: int = 2 ** 24
) -> int {
    return (multiplier * state + addend) % pmod;
}