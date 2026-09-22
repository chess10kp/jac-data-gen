"""Determine whether the scalar in the sequence."""
def scalar_in_sequence[T](x: T | None, y: list[T] | tuple[T, ...] | None) -> bool {
    if x is None {
        raise ValueError(
            "Judge scalar in tuple or list require scalar and sequence should be constant, "
            "but the scalar is not."
        );
    }
    if y is None {
        raise ValueError(
            "Judge scalar in tuple or list require scalar and sequence should be constant, "
            "but the sequence is not."
        );
    }
    if x in y {
        return True;
    }
    return False;
}