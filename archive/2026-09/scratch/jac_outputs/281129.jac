""" convert CIE1976 'v' to CIE1960 uv coordinates
    :param u76: ' value (CIE1976)
    :param v76: v' value (CIE1976)
    :return: CIE1960 u, v """
def uv76_to_uv60(u76: float, v76: float) -> tuple[float, float] {
    v60 = 2 * v76 / 3;
    return (u76, v60);
}