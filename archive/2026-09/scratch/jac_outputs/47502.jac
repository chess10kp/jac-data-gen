"""
    Validate the beacon configuration
    """
def validate(config: list[dict[str, str]]) -> tuple[bool, str] {
    _config = {};
    list(map(_config.update, config));
    if not isinstance(config, list) {
        return (False, "Configuration for log beacon must be a list.");
    }
    if "file" not in _config {
        return (False, "Configuration for log beacon must contain file option.");
    }
    return (True, "Valid beacon configuration");
}