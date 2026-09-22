"""Soma x e y."""
def soma(x: int | float, y: int | float) -> int | float {
    assert isinstance(x, (int, float)), "x precisa ser int ou float";
    assert isinstance(y, (int, float)), "y precisa ser int ou float";
    return x + y;
}