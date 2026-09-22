"""
    Map a quadrant number to Moran's I designation
    HH=1, LH=2, LL=3, HL=4
    Args:
      coord (int): quadrant of a specific measurement
    Returns:
      classification (one of 'HH', 'LH', 'LL', or 'HL')
    """
def map_quads(coord: Any) -> object {
    if (coord == 1) {
        return 'HH';
    } elif (coord == 2) {
        return 'LH';
    } elif (coord == 3) {
        return 'LL';
    } elif (coord == 4) {
        return 'HL';
    }
    return None;
}