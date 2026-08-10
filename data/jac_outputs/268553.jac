"""Return indices of primes from a precomputed sieve."""
def get_list_of_primes_pre_calc(gen: list[bool]) -> list[int] {
    return [ind for (ind, i) in enumerate(gen) if i];
}