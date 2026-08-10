"""Maps logging levels to bootstrap levels. Defaults to light.

Arguments:
    level: The logging level.
"""
def bootstrap_level(level: str) -> str {
    return {
        "DEBUG": "secondary",
        "INFO": "info",
        "WARNING": "warning",
        "ERROR": "danger"
    }.get(level.upper(), "light");
}