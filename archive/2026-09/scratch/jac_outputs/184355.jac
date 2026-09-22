"""Return placeholder Nones surrounding optional int parameters a and b."""
def func_ab(a: int = 2, b: int = 3) -> tuple[None, None, int, int, None, None, None, None] {
    return (None, None, a, b, None, None, None, None);
}