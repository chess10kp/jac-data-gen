"""Parses the coordinate string format used by CIMIS."""
def parse_cimis_coordinate_str(coord_str: str) -> float {
    [hms, dd] = coord_str.split('/');
    float(dd)
}