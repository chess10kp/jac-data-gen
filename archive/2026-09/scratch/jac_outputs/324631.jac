"""Modify this set to be the union of itself an another set."""
def __ior__[T](self: set[T], other: set[T]) -> set[T] {
    for e in other {
        self.add(e);
    }
    return self;
}