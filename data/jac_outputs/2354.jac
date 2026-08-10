glob MINUTES_PER_DEGREE = 60;

"""
Calculate the shape of the global Earth relief grid given a resolution.
"""
def _shape_from_resolution(resolution: str) -> tuple[int, int] {
    minutes = int(resolution[:2]);
    nlat = 180 * MINUTES_PER_DEGREE // minutes + 1;
    nlon = 360 * MINUTES_PER_DEGREE // minutes + 1;
    return (nlat, nlon);
}