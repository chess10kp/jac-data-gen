"""Return the graph colour for the series specified."""
def get_colour(series_options: Any, series_name: Any) -> object {
    if (series_options is None) {
        return None;
    }
    if (series_name in series_options) {
        if ("colour" in series_options[series_name]) {
            return series_options[series_name]["colour"];
        }
    }
    return None;
}