"""
    Remove start and end points from all line entries before writing to file.
    """
def build_written_line_entry(line_list: Any) -> object {
    def _build_written_line_entry(coords: Any) -> object {
        `entry = {
            "geometry": {"coordinates": coords, "type": "LineString"},
            "type": "Feature"
        };
        return `entry;
    }
    ret = [];
    for line in line_list {
        ret.append(_build_written_line_entry(line["geometry"]["coordinates"]));
    }
    return ret;
}