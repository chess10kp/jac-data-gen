"""Generates dictionary with command settings."""
def command_settings(body_max: int = 102400000, time_max: int = 0) -> dict[str, int] {
    settings = {"body_max": int(body_max), "time_max": int(time_max)};
    return settings;
}