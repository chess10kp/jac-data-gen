"""Calculates the interpolated result intermediate between two slices:
         result = (1.-f)*S1 + f*S2"""
def weightSlice(S1: list[tuple[float, float, float]], S2: list[tuple[float, float, float]], f: float) -> list[tuple[float, float, float]] {
    ns = len(S1);
    rt = [];
    for i in range(0, ns) {
        if S1[i][0] < 0 or S2[i][0] < 0 {
            rt.append((-32767.0, -32767.0, -32767.0));
        } else {
            r0 = (1.0 - f) * S1[i][0] + f * S2[i][0];
            r1 = (1.0 - f) * S1[i][1] + f * S2[i][1];
            r2 = (1.0 - f) * S1[i][2] + f * S2[i][2];
            rt.append((r0, r1, r2));
        }
    }
    return rt;
}