"""List l without element x."""
def rm[T](x: T, l: list[T]) -> list[T] {
    return [y for y in l if x != y];
}