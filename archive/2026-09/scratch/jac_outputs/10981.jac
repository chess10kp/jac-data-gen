"""Calculate heart rate in beat/min from estimated interval length"""
def ni_to_hr(ni: int, f: float) -> float {
    if ni == -1 {
        return -1;
    }
    return 60.0 * f / ni;
}