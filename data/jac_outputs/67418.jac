"""Builds the settings dictionary which peers use to pass settings information back and forth."""
def build_settings_dictionary(
    id_string: str,
    start_time: int | float,
    redis_connection_string: str,
    shared_memory_max_size: int,
    ordered_ownership_stop_threshold: int | float,
    ordered_ownership_start_threshold: int | float
) -> dict[str, str | int | float] {
    settings_dict = dict();
    settings_dict["id"] = id_string;
    settings_dict["start_time"] = start_time;
    settings_dict["sm_connection"] = redis_connection_string;
    settings_dict["sm_max"] = shared_memory_max_size;
    settings_dict["oq_stop"] = ordered_ownership_stop_threshold;
    settings_dict["oq_start"] = ordered_ownership_start_threshold;
    return settings_dict;
}