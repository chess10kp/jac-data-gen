"""
    Multiplies vector _V (in place) by number _a
    """
def vect_mult(_V: list[float], _a: float) -> list[float] {
    for i in range(len(_V)) {
        _V[i] *= _a;
    }
    return _V;
}