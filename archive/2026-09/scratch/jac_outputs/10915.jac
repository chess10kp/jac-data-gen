import from typing { SupportsFloat }

"""Comparison of ValueWithError object with other objects
    >>> a = VE( ... )
    >>> print a < b
    Attention: comparison by value only!
    """
def _ve_lt_(self: SupportsFloat, other: SupportsFloat) -> bool {
    return float(self) < float(other);
}