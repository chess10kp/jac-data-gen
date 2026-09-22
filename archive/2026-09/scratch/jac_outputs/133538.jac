"""
last :: [a] -> a

Extract the last element of a list, which must be finite and non-empty.
"""
def last[T](xs: list[T]) -> T {
    return xs[-1];
}