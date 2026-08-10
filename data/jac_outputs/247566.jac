"""Returns the volume of the primitive cell: |a1.(a2xa3)|."""
def cell_volume(a1: list[float], a2: list[float], a3: list[float]) -> float {
    a_mid_0 = a2[1] * a3[2] - a2[2] * a3[1];
    a_mid_1 = a2[2] * a3[0] - a2[0] * a3[2];
    a_mid_2 = a2[0] * a3[1] - a2[1] * a3[0];
    return abs(float(a1[0] * a_mid_0 + a1[1] * a_mid_1 + a1[2] * a_mid_2));
}