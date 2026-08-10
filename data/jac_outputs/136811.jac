"""Checks whether the advanced options box should be enabled by checking if any of the advanced options have existing values."""
def check_if_advanced_options_should_be_enabled(advanced_fields: list[str | int | float | bool | None]) -> bool {
    return any(item is not None for item in advanced_fields);
}