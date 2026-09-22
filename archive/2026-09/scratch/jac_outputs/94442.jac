""" convert RGB to YUV color
    :param Y: Y value (0;1)
    :param Db: Db value (-1.333-1.333)
    :param Dr: Dr value (-1.333-1.333)
    :return: YUV (PAL) tuple (Y0;1 U-0.436-0.436 V-0.615-0.615) """
def YDbDrtoYUV(Y: float, Db: float, Dr: float) -> tuple[float, float, float] {
    U = Db / 3.059;
    V = Dr / -2.169;
    return (Y, U, V);
}