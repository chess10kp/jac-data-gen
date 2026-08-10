"""Add value v to each element of the tuple t."""
def t_add(t: tuple[int, ...], v: int) -> tuple[int, ...] {
    return tuple((i + v) for i in t);
}