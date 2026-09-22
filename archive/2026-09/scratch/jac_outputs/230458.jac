"""
Automatically sets the "TIMED_APPEND" App Configuration variable to "TRUE" if
the "append" option is enabled and the cardinality parameter is set to "one".
"""
def ensure_timed_append_if_cardinality_one(
    config: dict[str, dict[str, str]],
    extra_config: dict[str, str],
    app_type: str,
    app_path: str
) -> dict[str, dict[str, str]] {
    if (
        extra_config["append"].lower() == "true"
        and "cardinality" in extra_config
        and extra_config["cardinality"].lower() == "one"
    ) {
        config["Values"]["TIMED_APPEND"] = "TRUE";
    }
    return config;
}