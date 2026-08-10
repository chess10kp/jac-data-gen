"""Determines if an 11-digit GEOID refers to the same place as a six-digit Chicago census tract ID."""
def tract_id_equals(tract_id: str, geo_id: str) -> bool {
    return geo_id.startswith("1703") and tract_id == geo_id[-6:];
}