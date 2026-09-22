"""Canonicalize the representation of an undirected edge.

Works by returning a sorted tuple.
"""
def cer(e: list[int]) -> tuple[int, ...] {
    return tuple(sorted(e));
}