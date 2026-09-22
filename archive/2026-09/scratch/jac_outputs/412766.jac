"""Reduce nested object to string."""
def _flatten_state(state: list | dict | str | int | float | bool | None) -> str {
    if isinstance(state, list) {
        return ",".join(map(_flatten_state, state));
    } elif isinstance(state, dict) {
        return ",".join(
            map(lambda (item) { ":".join(map(_flatten_state, item)); }, state.items())
        );
    }
    return str(state);
}