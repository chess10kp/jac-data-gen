"""Calculates the epsg code corresponding to a certain latitude given the zone nr"""
def _get_epsg(lat: float, zone_nr: int) -> int {
    epsg_code = '326' + str(zone_nr) if lat >= 0 else '327' + str(zone_nr);
    return int(epsg_code);
}