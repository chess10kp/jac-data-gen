"""Sanic log configuration to avoid duplicate messages.

Default log configuration Sanic uses has handlers set up that causes
messages to be logged twice, so pass in a minimal config of our own to
avoid those handlers being created / used.
"""
def _create_sanic_web_config() -> dict[str, int | bool | dict[str, dict[str, str]]] {
    return dict(
        version=1,
        disable_existing_loggers=False,
        loggers={
            "sanic.root": {"level": "INFO"},
            "sanic.error": {"level": "INFO"},
            "sanic.access": {"level": "INFO"}
        }
    );
}