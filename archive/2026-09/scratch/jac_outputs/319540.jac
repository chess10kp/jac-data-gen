"""Bits before n exclusive, indexing from 0"""
def before(n: Any) -> object {
    return ((1 << n) - 1);
}