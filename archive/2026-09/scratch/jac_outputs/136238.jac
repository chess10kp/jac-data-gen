"""
    calculates the antipode of list of directions
    """
def doreverse_list(decs: list[float], incs: list[float]) -> tuple[list[float], list[float]] {
    incs_flipped = [-i for i in incs];
    decs_flipped = [(dec + 180.0) % 360.0 for dec in decs];
    return (decs_flipped, incs_flipped);
}