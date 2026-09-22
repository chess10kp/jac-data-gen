"""Return euklidian distance between atoms coord1 and coord2."""
def euklid_dist(coord1: list[float], coord2: list[float]) -> float {
    xd2 = (coord1[0] - coord2[0]) ** 2;
    yd2 = (coord1[1] - coord2[1]) ** 2;
    zd2 = (coord1[2] - coord2[2]) ** 2;
    return (xd2 + yd2 + zd2) ** 0.5;
}