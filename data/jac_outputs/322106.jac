"""
    Returns the unit string corresponding to QUANTITY_NAME, or None if an error
    occurs during name extraction.
    """
def get_unit(quantity_name: Any) -> object {
    if not quantity_name {
        return None;
    }
    if ("power" in quantity_name) {
        unit = "kW";
    } elif ("energy" in quantity_name) {
        unit = "kWh";
    } else {
        unit = "unknown";
    }
    return unit;
}