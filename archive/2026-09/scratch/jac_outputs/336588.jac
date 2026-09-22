"""
    Given :math:`U_d` and :math:`J_H`, return :math:`F_0`, :math:`F_2` and :math:`F_4`.
"""
def UdJH_to_F0F2F4(Ud: float, JH: float) -> tuple[float, float, float] {
    F0 = Ud;
    F2 = 14 / 1.625 * JH;
    F4 = 0.625 * F2;
    return (F0, F2, F4);
}