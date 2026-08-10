"""Parses option_settings as they are defined in the configuration file."""
def parse_option_settings(option_settings: dict[str, dict[str, str]]) -> list[tuple[str, str, str]] {
    return [
        (namespace, key, value)
        for (namespace, params) in option_settings.items()
        for (key, value) in params.items()
    ];
}