"""
    Helper method to remove current ap from neighboring aps and return
    list of neighboring ap ids
    """
def get_neighboring_ap_ids(
    current_ap_location: list | tuple,
    neighboring_aps: list[tuple],
    location_to_ap_lookup: dict[tuple, str]
) -> list[str] {
    neighboring_ap_ids = [];
    if isinstance(current_ap_location, list) {
        current_ap_location = tuple(current_ap_location);
    }
    for ap_location in neighboring_aps {
        if current_ap_location != ap_location {
            neighboring_ap_ids.append(location_to_ap_lookup[ap_location]);
        }
    }
    return neighboring_ap_ids;
}