"""Slightly more clever way to find the collatz length.

A dictionary is used as a cache of previous results, and since
the dictionary passed in is mutable, our changes will reflect
in the caller.
"""
def collatz_len_fast(n: int, cache: dict[int, int]) -> int {
    if n == 1 {
        return 1;
    }
    if n in cache {
        return cache[n];
    }
    if n % 2 == 0 {
        cache[n] = collatz_len_fast(n // 2, cache) + 1;
    } else {
        cache[n] = collatz_len_fast(3 * n + 1, cache) + 1;
    }
    return cache[n];
}