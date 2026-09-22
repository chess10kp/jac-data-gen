"""VPD dependent reduction function of the biome dependent potential conductance"""
def mVPD(vpd: float, vpdclose: float, vpdopen: float) -> float {
    if vpd <= vpdopen {
        return 1.0;
    } elif vpd >= vpdclose {
        return 1.0;
    } else {
        return (vpdclose - vpd) / (vpdclose - vpdopen);
    }
}