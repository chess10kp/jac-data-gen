"""Construct polygon coordinates in page representation from a numeric list representing a bounding box."""
def points_from_bbox(minx: int, miny: int, maxx: int, maxy: int) -> str {
    return "%i,%i %i,%i %i,%i %i,%i" % (minx, miny, maxx, miny, maxx, maxy, minx, maxy);
}