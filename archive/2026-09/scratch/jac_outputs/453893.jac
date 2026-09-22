"""Map serial number."""
def map_serial_number(facilities: Any) -> str {
    facility = facilities.get("body", {}).get("facilitiesList", [])[0];
    return str(facility.get("serialNumber", None));
}