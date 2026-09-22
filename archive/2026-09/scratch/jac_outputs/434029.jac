"""Transforms [v1,v2] and returns it such that it is in the same order and has the same middle interval as [gm1, gm2]."""
def switchAndTranslate(
    gm1: float, gm2: float, v1: float, v2: float, wrapModulo: bool
) -> list[float] {
    assert v1 < v2;
    if wrapModulo {
        gmMiddle = float(gm1 + gm2) / 2.0;
        half = float(v2 - v1) / 2.0;
        v1 = gmMiddle - half;
        v2 = gmMiddle + half;
    }
    if (gm1 - gm2) * (v1 - v2) < 0 {
        (v1, v2) = (v2, v1);
    }
    return [v1, v2];
}