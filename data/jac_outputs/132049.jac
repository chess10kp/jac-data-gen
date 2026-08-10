"""
    Removes dates that are not in the range of start_date.day to end_date.day
    """
def filter_availability(availability: Any, start_date: Any, end_date: Any) -> object {
    filtered_availability = [];
    for time_range in availability {
        if (time_range["start"] < start_date) {
            continue;
        }
        if (time_range["end"] <= end_date) {
            filtered_availability.append(time_range);
        }
    }
    return filtered_availability;
}