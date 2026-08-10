def get_config_value(
    key_path: str,
    config: dict[str, str | int | float | bool | list[str] | dict] | None
) -> str | int | float | bool | list[str] | dict | None {
    if config is None {
        return None;
    }
    current_section: str | int | float | bool | list[str] | dict = config;
    for key in key_path.split(".") {
        if key in current_section {
            current_section = current_section[key];
        } else {
            return None;
        }
    }
    return current_section;
}