"""
    Definition
    ---
    Method to check if point is valid and clear of obstacles

    Parameters
    ---
    point : node of intrest
    validPoints : list of all valid points
    clearance : minimum distance required from obstacles

    Returns
    ---
    bool : True if point is valid, False othervise
    """
def isPointValid(point: tuple[int, int], validPoints: list[tuple[int, int]], clearance: int) -> bool {
    for i in range(-clearance, clearance) {
        for j in range(-clearance, clearance) {
            if (point[0] + i, point[1] + j) not in validPoints {
                return False;
            }
        }
    }
    return True;
}