"""
flip :: (a -> b -> c) -> b -> a -> c

flip(f) takes its (first) two arguments in the reverse order of f.
"""
def flip[T, U, R](f: Callable[[T, U], R], b: U, a: T) -> R {
    return f(a, b);
}