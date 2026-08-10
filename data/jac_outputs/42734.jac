"""For a given maximum, return the list of symbols to compute permutations for.
For instance, 3 would return ['0', '1', '2', '3']"""
def make_symbol_list(maximum: int) -> list[str] {
    [str(i) for i in range(maximum + 1)]
}