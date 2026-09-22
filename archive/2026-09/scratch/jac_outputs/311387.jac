"""
    Build the json for an InfluxDB data point.
    """
def _build_influxdb_point(
    unix_ts_secs: Any, tags: Any, measurement: Any, fields: Any
) -> object {
    timestamp_ns = unix_ts_secs * 1000000000;
    point_json = {
        "measurement": measurement,
        "tags": tags,
        "time": timestamp_ns,
        "fields": {}
    };
    for (field_name, field_value) in fields {
        point_json["fields"][field_name] = field_value;
    }
    return point_json;
}