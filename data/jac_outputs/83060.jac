"""Get lat, lon list from state alert list"""
def get_location_list(state_alert_list: Any) -> object {
    locations = [];
    for item in state_alert_list {
        locations.append([item["lat"], item["lon"]]);
    }
    return locations;
}