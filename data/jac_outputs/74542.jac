"""Convert list or dict of triggers to MNE-style event_id."""
def triggers_to_event_id(triggers: list[int] | dict[str, int] | dict[str, float]) -> dict[str, int] {
    triggers_dict: dict[str, int] | dict[str, float];
    if isinstance(triggers, list) {
        triggers_dict = {str(trigger): trigger for trigger in triggers};
    } else {
        assert isinstance(triggers, dict), '`triggers` must be either list or dict';
        triggers_dict = triggers as dict[str, int] | dict[str, float];
    }
    return {key: int(value) for (key, value) in triggers_dict.items()};
}